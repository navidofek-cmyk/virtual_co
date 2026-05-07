from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from jose import jwt, JWTError
import psycopg2
import psycopg2.extras
import subprocess
import httpx
import json
import os

# ── Config ────────────────────────────────────────────────────
DB_URL       = "host=localhost port=5432 dbname=savanah user=postgres password=savanah123"
SECRET       = "savanah-secret-key"
ALGO         = "HS256"

try:
    _cfg         = json.load(open("config.json"))
    FLOW_ID      = _cfg["flow_id"]
    LANGFLOW_URL = _cfg["langflow_url"]
    LF_KEY       = _cfg["lf_key"]
except Exception:
    FLOW_ID = LANGFLOW_URL = LF_KEY = None


app    = FastAPI(title="Private AI Agent API")
bearer = HTTPBearer()

# ── DB ────────────────────────────────────────────────────────
def get_db():
    conn = psycopg2.connect(DB_URL)
    conn.cursor_factory = psycopg2.extras.RealDictCursor
    return conn

# ── Langflow token (interní, uživatel nevidí) ─────────────────
def call_agent(prompt: str) -> str:
    """Pošle prompt do Langflow (Claude CLI komponenta) nebo přímo claude -p."""
    if FLOW_ID and LANGFLOW_URL:
        try:
            r = httpx.post(
                f"{LANGFLOW_URL}/api/v1/run/{FLOW_ID}",
                json={"input_value": prompt, "input_type": "text", "output_type": "text"},
                headers={"x-api-key": LF_KEY},
                timeout=60,
            )
            data = r.json()
            return (data["outputs"][0]["outputs"][0]["results"]["text"]["data"]["text"])
        except Exception:
            pass
    # Fallback – přímé volání claude -p
    result = subprocess.run(["claude", "-p", prompt],
                            capture_output=True, text=True, timeout=60)
    return result.stdout.strip() or "Žádná odpověď."

# ── Auth helpers ──────────────────────────────────────────────
class LoginRequest(BaseModel):
    email: str

def current_user(creds: HTTPAuthorizationCredentials = Depends(bearer)):
    try:
        return jwt.decode(creds.credentials, SECRET, algorithms=[ALGO])
    except JWTError:
        raise HTTPException(status_code=401, detail="Neplatný token")

# ── Skutečné DB dotazy podle role ────────────────────────────
def fetch_data(source: str, user: dict, cur) -> str:
    role      = user["role"]
    branch_id = user.get("branch_id")
    user_id   = user["id"]
    org_id    = user["organization_id"]

    if source == "ds-transactions":
        if role == "TELLER":
            cur.execute("""
                SELECT t.amount, t.currency, t.transaction_date, t.category, t.fraud_score
                FROM transactions t
                JOIN accounts a ON t.account_id = a.id
                JOIN customers c ON a.customer_id = c.id
                WHERE c.assigned_teller = %s AND t.organization_id = %s
                ORDER BY t.transaction_date DESC LIMIT 10
            """, (user_id, org_id))
        elif role in ("BRANCH_MANAGER", "SENIOR_TELLER"):
            cur.execute("""
                SELECT amount, currency, transaction_date, category, fraud_score
                FROM transactions WHERE branch_id = %s AND organization_id = %s
                ORDER BY transaction_date DESC LIMIT 20
            """, (branch_id, org_id))
        elif role == "REGIONAL_DIRECTOR":
            cur.execute("""
                SELECT branch_id, COUNT(*) as pocet, SUM(amount) as obrat
                FROM transactions WHERE organization_id = %s
                GROUP BY branch_id ORDER BY obrat DESC
            """, (org_id,))
        elif role in ("RISK_MANAGER",):
            cur.execute("""
                SELECT * FROM v_transactions_risk
                WHERE organization_id = %s ORDER BY fraud_score DESC LIMIT 20
            """, (org_id,))
        elif role == "COMPLIANCE_OFFICER":
            cur.execute("""
                SELECT * FROM v_transactions_suspicious
                WHERE organization_id = %s ORDER BY fraud_score DESC
            """, (org_id,))
        else:
            cur.execute("""
                SELECT branch_id, COUNT(*) as pocet, SUM(amount) as obrat
                FROM transactions WHERE organization_id = %s GROUP BY branch_id
            """, (org_id,))

    elif source == "ds-clients":
        if role == "TELLER":
            cur.execute("""
                SELECT full_name, phone_masked, email_masked, kyc_status, risk_level
                FROM v_customer_basic
                WHERE assigned_teller = %s AND organization_id = %s
            """, (user_id, org_id))
        elif role in ("BRANCH_MANAGER", "SENIOR_TELLER"):
            cur.execute("""
                SELECT full_name, risk_level, kyc_status
                FROM v_customer_branch
                WHERE branch_id = %s AND organization_id = %s
            """, (branch_id, org_id))
        else:
            cur.execute("""
                SELECT branch_id, COUNT(*) as klientu,
                       SUM(CASE WHEN risk_level='HIGH' THEN 1 ELSE 0 END) as vysoke_riziko
                FROM customers WHERE organization_id = %s GROUP BY branch_id
            """, (org_id,))

    elif source == "ds-hr":
        if role == "HR_MANAGER":
            cur.execute("""
                SELECT full_name, email, department_id, branch_id, is_active
                FROM users WHERE organization_id = %s ORDER BY full_name
            """, (org_id,))
        else:
            cur.execute("""
                SELECT full_name, email, branch_id
                FROM users WHERE organization_id = %s AND is_active = true ORDER BY full_name
            """, (org_id,))

    elif source == "ds-finance":
        cur.execute("""
            SELECT branch_id, COUNT(*) as uctu,
                   SUM(balance) as celkove_zustatky,
                   AVG(balance) as prumerny_zustatek
            FROM accounts WHERE organization_id = %s AND status = 'ACTIVE'
            GROUP BY branch_id ORDER BY celkove_zustatky DESC
        """, (org_id,))

    else:
        return "Neznámý datový zdroj."

    rows = cur.fetchall()
    if not rows:
        return "Žádná data."
    return "\n".join(str(dict(r)) for r in rows)

# ── Endpoints ─────────────────────────────────────────────────

@app.post("/auth/login")
def login(body: LoginRequest):
    """Přihlášení → JWT token pro uživatele."""
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT u.id, u.full_name, u.email, u.branch_id, u.region_id,
               u.organization_id, r.name as role
        FROM users u
        JOIN user_roles ur ON u.id = ur.user_id
        JOIN roles r ON ur.role_id = r.id
        WHERE u.email = %s AND u.is_active = true
    """, (body.email,))
    user = cur.fetchone()
    db.close()
    if not user:
        raise HTTPException(status_code=401, detail="Uživatel nenalezen")
    token = jwt.encode(dict(user), SECRET, algorithm=ALGO)
    return {"token": token, "user": {"name": user["full_name"], "email": user["email"],
                                      "role": user["role"], "branch": user["branch_id"],
                                      "region": user["region_id"]}}


@app.get("/me")
def me(user=Depends(current_user)):
    return {"name": user["full_name"], "email": user["email"],
            "role": user["role"], "branch": user["branch_id"]}


@app.get("/agents")
def list_agents(user=Depends(current_user)):
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT 1 FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = %s AND p.code = 'agents.run'
    """, (user["id"],))
    if not cur.fetchone():
        db.close()
        raise HTTPException(status_code=403, detail="Nemáš právo spouštět agenty")
    cur.execute("SELECT id, name, description FROM agents WHERE organization_id = %s AND is_active = true",
                (user["organization_id"],))
    agents = cur.fetchall()
    db.close()
    return agents


class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None


@app.post("/agents/{agent_id}/chat")
def chat(agent_id: str, body: ChatRequest, user=Depends(current_user)):
    db = get_db()
    cur = db.cursor()

    cur.execute("SELECT * FROM agents WHERE id = %s AND organization_id = %s",
                (agent_id, user["organization_id"]))
    if not cur.fetchone():
        db.close()
        raise HTTPException(status_code=404, detail="Agent nenalezen")

    # Conversation — vytvoř nebo načti existující
    conv_id = body.conversation_id
    if not conv_id:
        cur.execute("""
            INSERT INTO conversations (id, organization_id, user_id, agent_id, title)
            VALUES (gen_random_uuid()::text, %s, %s, %s, %s)
            RETURNING id
        """, (user["organization_id"], user["id"], agent_id,
              body.message[:60]))
        conv_id = cur.fetchone()["id"]

    # Access rules
    cur.execute("""
        SELECT dar.resource_id, dar.access_level
        FROM data_access_rules dar
        JOIN user_roles ur ON dar.subject_id = ur.role_id
        WHERE ur.user_id = %s AND dar.subject_type = 'role' AND dar.organization_id = %s
        ORDER BY dar.priority DESC
    """, (user["id"], user["organization_id"]))
    rules      = cur.fetchall()
    accessible = [r["resource_id"] for r in rules if r["access_level"] in ("read", "write")]

    data_context = "\n".join(
        f"--- {src} ---\n{fetch_data(src, dict(user), cur)}"
        for src in accessible
    ) or "Žádná data nejsou dostupná."

    prompt = f"""Jsi FinanceBot — bankovní asistent Banky Morava.

Uživatel: {user['full_name']} | Role: {user['role']} | Umístění: {user.get('branch_id') or user.get('region_id') or 'ústředí'}

Dostupná data:
{data_context}

Dotaz: {body.message}

Pokud se uživatel ptá na data která nejsou výše uvedena, zdvořile odmítni.
Odpověz stručně a věcně v češtině."""

    answer = call_agent(prompt)

    # Ulož do chat history (agent_runs)
    cur.execute("""
        INSERT INTO agent_runs (id, conversation_id, user_id, agent_id, question, answer, status)
        VALUES (gen_random_uuid()::text, %s, %s, %s, %s, %s, 'completed')
    """, (conv_id, user["id"], agent_id, body.message, answer))

    # Audit log
    cur.execute("""
        INSERT INTO audit_logs (id, organization_id, user_id, action, entity_type, entity_id, details)
        VALUES (gen_random_uuid()::text, %s, %s, 'agent_query', 'conversation', %s, %s::jsonb)
    """, (user["organization_id"], user["id"], conv_id,
          json.dumps({"agent": agent_id, "role": user["role"], "accessible": accessible})))

    db.commit()
    db.close()

    return {
        "answer":          answer,
        "conversation_id": conv_id,
        "user":            user["full_name"],
        "role":            user["role"],
        "data_scope":      accessible,
    }


@app.get("/conversations")
def list_conversations(user=Depends(current_user)):
    """Moje konverzace."""
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT c.id, c.title, c.created_at,
               COUNT(ar.id) as zprav
        FROM conversations c
        LEFT JOIN agent_runs ar ON ar.conversation_id = c.id
        WHERE c.user_id = %s
        GROUP BY c.id ORDER BY c.created_at DESC LIMIT 20
    """, (user["id"],))
    convs = cur.fetchall()
    db.close()
    return convs


@app.get("/conversations/{conv_id}")
def get_conversation(conv_id: str, user=Depends(current_user)):
    """Historie jedné konverzace."""
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT question, answer, created_at
        FROM agent_runs
        WHERE conversation_id = %s AND user_id = %s
        ORDER BY created_at ASC
    """, (conv_id, user["id"]))
    history = cur.fetchall()
    db.close()
    return history


@app.get("/audit")
def audit_logs(user=Depends(current_user)):
    if user["role"] != "COMPLIANCE_OFFICER":
        raise HTTPException(status_code=403, detail="Přístup pouze pro Compliance")
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT al.created_at, u.full_name, al.action, al.details
        FROM audit_logs al JOIN users u ON al.user_id = u.id
        WHERE al.organization_id = %s ORDER BY al.created_at DESC LIMIT 50
    """, (user["organization_id"],))
    logs = cur.fetchall()
    db.close()
    return logs
