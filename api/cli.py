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
        print("API není dostupné. Spusť: uv run python -m uvicorn main:app --port 8000")
        sys.exit(1)


def prihlasit(email: str):
    r = httpx.post(f"{API}/auth/login", json={"email": email})
    if r.status_code != 200:
        print(f"Chyba: {r.json().get('detail')}")
        sys.exit(1)
    d = r.json()
    return d["token"], d["user"]


def hlavni():
    uzivatele = nacti_uzivatele()

    print("\n╔══ Banka Morava – FinanceBot ══════════════════════════════════╗")
    print(f"║  {'#':>2}  {'Jméno':<25} {'Role':<20} {'Umístění':<12}║")
    print("╠═══════════════════════════════════════════════════════════════╣")
    for i, u in enumerate(uzivatele, 1):
        print(f"║  {i:>2}. {u['full_name']:<25} {u['role']:<20} {u['umisteni']:<12}║")
    print("╚═══════════════════════════════════════════════════════════════╝")

    volba = input("\nZadej číslo (nebo email): ").strip()
    try:
        email = uzivatele[int(volba) - 1]["email"]
    except (ValueError, IndexError):
        email = volba

    token, user = prihlasit(email)

    print(f"\n✓ Přihlášen: {user['name']}")
    print(f"  Role:      {user['role']}")
    print(f"  Umístění:  {user['branch'] or user.get('region') or 'ústředí'}")
    print(f"\nFinanceBot → Langflow → Claude")
    print(f"Napiš 'konec' pro ukončení.")
    print("─" * 50)

    conversation_id = None

    while True:
        try:
            zprava = input("\nTy: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nNashledanou!")
            break

        if zprava.lower() in ("konec", "exit", "q"):
            print("Nashledanou!")
            break
        if zprava.lower() == "historie":
            r = httpx.get(f"{API}/conversations",
                          headers={"Authorization": f"Bearer {token}"})
            for c in r.json():
                print(f"  [{c['created_at'][:16]}] {c['title']} ({c['zprav']} zpráv) – id: {c['id']}")
            continue
        if not zprava:
            continue

        r = httpx.post(
            f"{API}/agents/agent-financebot/chat",
            json={"message": zprava, "conversation_id": conversation_id},
            headers={"Authorization": f"Bearer {token}"},
            timeout=30,
        )
        data = r.json()

        if "answer" in data:
            conversation_id = data["conversation_id"]
            print(f"\nFinanceBot: {data['answer']}")
            print(f"[zdroje: {', '.join(data.get('data_scope', []))}]")
        else:
            print(f"\nChyba: {data.get('detail', data)}")


if __name__ == "__main__":
    hlavni()
