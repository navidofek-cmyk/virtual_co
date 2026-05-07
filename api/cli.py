#!/usr/bin/env python3
"""
CLI klient – Private AI Agent Platform (Banka Morava)
Použití: uv run python cli.py
"""
import httpx
import sys

API = "http://localhost:8000"


def nacti_uzivatele() -> list:
    try:
        r = httpx.get(f"{API}/users/list", timeout=5)
        return r.json()
    except Exception:
        print("API not available. Run: uv run python -m uvicorn main:app --port 8000")
        sys.exit(1)


def prihlasit(email: str):
    r = httpx.post(f"{API}/auth/login", json={"email": email})
    if r.status_code != 200:
        print(f"Error: {r.json().get('detail')}")
        sys.exit(1)
    d = r.json()
    return d["token"], d["user"]


def hlavni():
    users = nacti_uzivatele()

    print("\n╔══ Banka Morava – FinanceBot ══════════════════════════════════╗")
    print(f"║  {'#':>2}  {'Name':<25} {'Role':<20} {'Location':<12}║")
    print("╠═══════════════════════════════════════════════════════════════╣")
    for i, u in enumerate(users, 1):
        print(f"║  {i:>2}. {u['full_name']:<25} {u['role']:<20} {u['umisteni']:<12}║")
    print("╚═══════════════════════════════════════════════════════════════╝")

    choice = input("\nEnter number (or email): ").strip()
    try:
        email = users[int(choice) - 1]["email"]
    except (ValueError, IndexError):
        email = choice

    token, user = prihlasit(email)

    print(f"\n✓ Logged in: {user['name']}")
    print(f"  Role:      {user['role']}")
    print(f"  Location:  {user['branch'] or user.get('region') or 'headquarters'}")
    print(f"\nFinanceBot → Claude")
    print(f"Type 'quit' to exit, 'history' to see past conversations.")
    print("─" * 50)

    conversation_id = None

    while True:
        try:
            message = input("\nYou: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nGoodbye!")
            break

        if message.lower() in ("quit", "exit", "q"):
            print("Goodbye!")
            break
        if message.lower() == "history":
            r = httpx.get(f"{API}/conversations",
                          headers={"Authorization": f"Bearer {token}"})
            for c in r.json():
                print(f"  [{c['created_at'][:16]}] {c['title']} ({c['zprav']} messages) – id: {c['id']}")
            continue
        if not message:
            continue

        r = httpx.post(
            f"{API}/agents/agent-financebot/chat",
            json={"message": message, "conversation_id": conversation_id},
            headers={"Authorization": f"Bearer {token}"},
            timeout=30,
        )
        data = r.json()

        if "answer" in data:
            conversation_id = data["conversation_id"]
            print(f"\nFinanceBot: {data['answer']}")
            print(f"[sources: {', '.join(data.get('data_scope', []))}]")
        else:
            print(f"\nError: {data.get('detail', data)}")


if __name__ == "__main__":
    hlavni()
