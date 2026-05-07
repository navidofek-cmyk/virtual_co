# Myšlenkový pochod – Private AI Agent Platform

---

## Odkud vycházíme (z meetingu s Jirkou)

Jirka to řekl jednoduše:

```text
Firmy budou mít svoje databáze, dokumentace, emaily.
My se na ně napojíme.
Ale zároveň musíme mít svoji vlastní databázi —
kde víme, kdo je přihlášený, jaká má práva, co smí dělat.
```

---

## Dva světy v jednom systému

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   NAŠE DATABÁZE              KLIENTOVA DATABÁZE    │
│   (vždy stejná)              (každý má jinou)      │
│                                                     │
│   - kdo je uživatel          - výrobní data        │
│   - jakou má roli            - transakce           │
│   - co smí dělat             - dokumenty           │
│   - audit logy               - emaily              │
│   - konfigurace agentů       - vlastní systémy     │
│                                                     │
│         ↓                         ↓                │
│              AI Agent dostane                       │
│         jen filtrovaná data z obou zdrojů          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Konkrétní příklady klientů (z meetingu)

### Raiffeisen banka
```text
Kdo se přihlásí?
→ přepážkový pracovník, manažer pobočky, risk analytik, HR

Co chce vědět?
→ transakce svých klientů, reporty pobočky, rizikové analýzy

Co nesmí vidět?
→ přepážková paní nesmí vidět mzdy kolegů
→ manažer Brno nesmí vidět Prahu
```

### Ocelárny
```text
Kdo se přihlásí?
→ mistr výroby, technolog, obchodník, ředitel

Co chce vědět?
→ stav výroby, objednávky, reklamace, kvalita materiálu

Co nesmí vidět?
→ mistr nesmí vidět obchodní smlouvy
→ obchodník nesmí vidět náklady výroby
```

---

## Naše databáze – co musí umět

### 1. Poznat uživatele
```text
Kdo jsi?
→ email + heslo, nebo SSO (Microsoft, Google)
→ z které firmy (organization)
→ z jakého oddělení (department)
```

### 2. Vědět co smí dělat
```text
Co smíš?
→ spustit agenta? (agents.run)
→ nahrát dokument? (documents.write)
→ vidět analytiku? (analytics.read)
→ spravovat uživatele? (users.manage)
```

### 3. Určit která data uvidí
```text
Která data dostane AI?
→ jen transakce z pobočky Brno
→ jen HR záznamy (bez mezd)
→ jen výroba za poslední týden
```

### 4. Zapamatovat si vše co se stalo
```text
Co se stalo?
→ kdo se ptal
→ na co se ptal
→ co AI dostala
→ co odpověděla
```

---

## Jak to uživatel zažije (od babky za přepážkou)

```
1. Přihlásí se
   → zadá email a heslo

2. Otevře agenta
   → "FinanceBot" nebo "VýrobníBot"

3. Napíše dotaz
   → "Kolik transakcí jsem dnes vyřídila?"

4. Systém za scénou
   → ověří ji
   → zjistí jaká má práva
   → vytáhne jen její data z databáze
   → pošle je agentovi

5. Dostane odpověď
   → "Dnes jsi vyřídila 12 transakcí."

6. Žádná magie — jen bezpečná práce s daty
```

---

## Co stavíme jako první (plán z meetingu)

```
KROK 1 – Databáze (teď)
  PostgreSQL schéma
  organizations, users, roles, permissions
  agents, data_sources, data_access_rules
  audit_logs

KROK 2 – Testovací data
  Vymyslíme si firmu (třeba "Banka Morava")
  Přidáme uživatele s různými rolemi
  Přidáme data_access_rules

KROK 3 – Langflow
  Zapojíme agenty
  Napojíme na databázi přes bezpečné API

KROK 4 – Testování lokálně
  Jirkův Mac Pro přes SSH

KROK 5 – Render
  Nahrajeme do cloudu
  Ukážeme klientům
```

---

## Otázky které musíme zodpovědět

```
□ Jak přesně aplikovat row_filter pro každého uživatele?
  → dynamicky podle user.branch_id?
  → nebo staticky uložit v pravidle?

□ Co když má uživatel víc rolí?
  → sečteme práva? nebo průnik?
  → kdo vyhraje při konfliktu?

□ Jak napojit Langflow na naši databázi bezpečně?
  → přes FastAPI endpoint?
  → nebo přímé připojení?

□ Jak poznat že uživatel patří ke správné firmě?
  → organization_id musí být na každém dotazu

□ Jak ukázat klientovi demo?
  → testovací firma s reálně vypadajícími daty
  → různé přihlašovací účty (teller, manažer, admin)
```

---

## Tým a role (z meetingu)

| Člověk | Role | Zaměření |
|---|---|---|
| Jirka Lamos | Lead / Architekt | celkový návrh, klienti, Rakousko |
| Ivan (ty) | Developer | databáze, Python, backend |
| Tony | Developer (Rakousko) | komponenty, testování |

**Komunikace:** angličtina (kvůli Tonymu)
**Meetingy:** 2x týdně, 1,5 hodiny
**Tempo:** ~10 dní na základní verzi

---

## Klíčová myšlenka celého projektu

```text
Firmy mají data.
Firmy chtějí AI.
Ale bojí se, že AI uvidí víc než má.

My jim dáme AI, která vidí přesně to co má —
a nic víc.

To je náš produkt.
```
