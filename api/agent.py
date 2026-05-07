#!/usr/bin/env python3
"""
Agent smyčka napsaná přímo v CLI.
Claude rozhoduje které nástroje zavolat, smyčka je tady.
Použití: uv run python agent.py
"""
import subprocess
import json
import httpx
import sys

API = "http://localhost:8000"

# ── Nástroje (tools) ──────────────────────────────────────────
TOOLS = {
    "get_transactions": {
        "popis":    "Vrátí data o transakcích",
        "data_src": "ds-transactions",
    },
    "get_clients": {
        "popis":    "Vrátí data o klientech",
        "data_src": "ds-clients",
    },
    "get_hr": {
        "popis":    "Vrátí HR záznamy zaměstnanců",
        "data_src": "ds-hr",
    },
    "get_finance": {
        "popis":    "Vrátí finanční výsledky",
        "data_src": "ds-finance",
    },
}

DEMO_DATA = {
    "ds-transactions": "247 transakcí tento týden, celkem 4 200 000 Kč, průměr 17 004 Kč.",
    "ds-clients":      "134 aktivních klientů, 8 nových tento měsíc, průměrné portfolio 450 000 Kč.",
    "ds-hr":           "87 zaměstnanců, 12 nastoupilo letos, průměrná délka 4,2 roku.",
    "ds-finance":      "Q1 2026: zisk 42 mil. Kč (+8 %), náklady 18 mil. Kč.",
}

# ── Volání nástroje ───────────────────────────────────────────
def volej_nastroj(name: str, accessible: list) -> str:
    tool = TOOLS.get(name)
    if not tool:
        return f"Neznámý nástroj: {name}"
    src = tool["data_src"]
    if src not in accessible:
        return f"Přístup zamítnut: nemáš právo na {name}"
    return DEMO_DATA.get(src, "Žádná data.")

# ── Agent smyčka ──────────────────────────────────────────────
def agent(dotaz: str, user: dict, accessible: list) -> str:
    tools_popis = "\n".join(
        f"- {name}: {t['popis']}"
        for name, t in TOOLS.items()
    )

    # Krok 1 — Claude rozhodne co zavolat
    plan_prompt = f"""Jsi FinanceBot — bankovní asistent.

Uživatel: {user['name']} | Role: {user['role']}
Dostupné nástroje:
{tools_popis}

Dotaz: {dotaz}

Rozhodni které nástroje musíš zavolat pro odpověď.
Odpověz POUZE jako JSON seznam, např: ["get_transactions", "get_clients"]
Pokud nepotřebuješ žádný nástroj, vrať: []"""

    plan_result = subprocess.run(
        ["claude", "-p", plan_prompt],
        capture_output=True, text=True, timeout=30
    )
    raw = plan_result.stdout.strip()

    # Vytáhni JSON ze odpovědi
    try:
        start = raw.index("[")
        end   = raw.rindex("]") + 1
        needed_tools = json.loads(raw[start:end])
    except Exception:
        needed_tools = []

    # Krok 2 — Zavolej nástroje
    results = {}
    for tool_name in needed_tools:
        results[tool_name] = volej_nastroj(tool_name, accessible)

    # Krok 3 — Claude odpovídá s daty
    if results:
        data_text = "\n".join(f"- {k}: {v}" for k, v in results.items())
    else:
        data_text = "Žádná data nebyla načtena."

    answer_prompt = f"""Jsi FinanceBot — bankovní asistent Banky Morava.

Uživatel: {user['name']} | Role: {user['role']}

Data která jsi načetl:
{data_text}

Dotaz uživatele: {dotaz}

Odpověz stručně a věcně v češtině na základě dat výše.
Pokud data nejsou dostupná, zdvořile odmítni."""

    answer_result = subprocess.run(
        ["claude", "-p", answer_prompt],
        capture_output=True, text=True, timeout=30
    )
    return answer_result.stdout.strip()

# ── CLI ───────────────────────────────────────────────────────
UZIVATELE = {
    "1":  ("Jana Nováková",    "jana.novakova@banka-morava.cz"),
    "2":  ("Lucie Svobodová",  "lucie.svobodova@banka-morava.cz"),
    "3":  ("Tomáš Veselý",     "tomas.vesely@banka-morava.cz"),
    "4":  ("Jana Procházková", "jana.prochazkova@banka-morava.cz"),
    "5":  ("Martin Novák",     "martin.novak@banka-morava.cz"),
    "6":  ("Petra Horáčková",  "petra.horackova@banka-morava.cz"),
}

def prihlasit(email: str):
    r = httpx.post(f"{API}/auth/login", json={"email": email})
    if r.status_code != 200:
        print(f"Chyba: {r.json().get('detail')}")
        sys.exit(1)
    d = r.json()
    return d["token"], d["user"]

def get_accessible(token: str) -> list:
    r = httpx.post(
        f"{API}/agents/agent-financebot/chat",
        json={"message": "_ping"},
        headers={"Authorization": f"Bearer {token}"},
        timeout=10,
    )
    return r.json().get("data_scope", [])

def hlavni():
    print("\n╔══ FinanceBot Agent ════════════════════════════╗")
    for k, (jmeno, _) in UZIVATELE.items():
        print(f"║  {k}. {jmeno:<42}║")
    print("╚════════════════════════════════════════════════╝")

    volba = input("\nZadej číslo: ").strip()
    email = UZIVATELE.get(volba, ("", volba))[1]

    token, user = prihlasit(email)
    accessible  = get_accessible(token)

    print(f"\n✓ {user['name']} ({user['role']})")
    print(f"  Dostupné nástroje: {[t for t,v in TOOLS.items() if v['data_src'] in accessible]}")
    print(f"\nAgent smyčka: dotaz → Claude plánuje → volá nástroje → odpovídá")
    print("─" * 50)

    while True:
        try:
            dotaz = input("\nTy: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nNashledanou!")
            break
        if dotaz.lower() in ("konec", "q"):
            print("Nashledanou!")
            break
        if not dotaz:
            continue

        print("Agent přemýšlí...")
        odpoved = agent(dotaz, user, accessible)
        print(f"\nAgent: {odpoved}")

if __name__ == "__main__":
    hlavni()
