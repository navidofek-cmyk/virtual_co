#!/usr/bin/env python3
"""
CLI klient – Private AI Agent Platform (Banka Morava)
Použití: uv run python cli.py
"""
import httpx
import sys

API = "http://localhost:8000"

UZIVATELE = {
    "1":  ("Jana Nováková",       "jana.novakova@banka-morava.cz"),
    "2":  ("Karel Dvořák",        "karel.dvorak@banka-morava.cz"),
    "3":  ("Eva Blahová",         "eva.blahova@banka-morava.cz"),
    "4":  ("Lucie Svobodová",     "lucie.svobodova@banka-morava.cz"),
    "5":  ("Pavel Horák",         "pavel.horak@banka-morava.cz"),
    "6":  ("Tomáš Veselý",        "tomas.vesely@banka-morava.cz"),
    "7":  ("Alena Marková",       "alena.markova@banka-morava.cz"),
    "8":  ("Jana Procházková",    "jana.prochazkova@banka-morava.cz"),
    "9":  ("Marie Kratochvílová", "marie.kratochvilova@banka-morava.cz"),
    "10": ("Martin Novák",        "martin.novak@banka-morava.cz"),
    "11": ("Petra Horáčková",     "petra.horackova@banka-morava.cz"),
}


def prihlasit(email: str):
    r = httpx.post(f"{API}/auth/login", json={"email": email})
    if r.status_code != 200:
        print(f"Chyba: {r.json().get('detail')}")
        sys.exit(1)
    d = r.json()
    return d["token"], d["user"]


def hlavni():
    print("\n╔══ Banka Morava – FinanceBot ═══════════════════╗")
    print("║  Přihlas se jako:                              ║")
    for k, (jmeno, _) in UZIVATELE.items():
        print(f"║  {k:>2}. {jmeno:<36}║")
    print("╚════════════════════════════════════════════════╝")

    volba = input("\nZadej číslo (nebo email): ").strip()
    email = UZIVATELE[volba][1] if volba in UZIVATELE else volba

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
