# Virtual Co – Private AI Agent Platform

Bezpečná multi-tenant platforma pro AI agenty v enterprise prostředí.
Ukazuje jak správně implementovat access control **před** tím, než LLM dostane data.

---

## Co to je

Firmy chtějí AI, ale bojí se dat. Tato platforma zajistí, že každý zaměstnanec vidí přesně ta data, na která má právo — nic víc.

```
Přepážková paní → vidí jen své klienty
Manažer pobočky → vidí celou pobočku
Risk analytik   → vidí vše, ale bez jmen klientů
HR              → vidí zaměstnance, ne transakce
```

---

## Architektura

```
Uživatel
    ↓
CLI / Browser
    ↓
FastAPI  (auth → RBAC → filtrování dat)
    ↓
Agent smyčka  (Claude rozhoduje které nástroje zavolat)
    ↓
claude -p  (Max subscription, bez API klíče)
    ↓
Odpověď uložena do DB (conversations + agent_runs)
```

---

## Rychlý start

### Požadavky
- Docker
- Python 3.12+
- [uv](https://github.com/astral-sh/uv)
- Claude Code CLI

### 1. Spusť databázi
```bash
docker run --name virtual-co-db \
  -e POSTGRES_PASSWORD=savanah123 \
  -e POSTGRES_DB=savanah \
  -p 5432:5432 -d postgres:16
```

### 2. Vytvoř schéma a seed data
```bash
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/schema.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_banka_morava.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_rozsireni.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_praha.sql
```

### 3. Spusť API
```bash
cd api
uv sync
uv run uvicorn main:app --port 8000
```

### 4. Spusť CLI klienta
```bash
uv run python cli.py
```

### 5. Nebo spusť agenta s nástroji
```bash
uv run python agent.py
```

---

## Demo – Banka Morava a.s.

21 zaměstnanců, 5 poboček, 11 rolí.

---

### Kdo má přístup kam

> 🟢 plný přístup &nbsp; 🟡 částečný / maskovaný &nbsp; 🔴 zakázáno

| Role | Klienti | Účty | Transakce | Úvěry | HR | Finance | Audit |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **TELLER** | 🟡 vlastní | 🟡 maskovaně | 🟡 omezeno | 🔴 | 🔴 | 🔴 | 🔴 |
| **BRANCH_MANAGER** | 🟡 pobočka | 🟢 pobočka | 🟢 pobočka | 🔴 | 🔴 | 🟡 pobočka | 🔴 |
| **REGIONAL_DIRECTOR** | 🟡 region | 🟢 region | 🟢 region | 🔴 | 🔴 | 🟡 region | 🔴 |
| **RISK_MANAGER** | 🔴 bez PII | 🟡 bez PII | 🟢 bez PII | 🟢 scoring | 🔴 | 🔴 | 🔴 |
| **COMPLIANCE_OFFICER** | 🟡 KYC/AML | 🔴 | 🟡 podezřelé | 🔴 | 🔴 | 🔴 | 🟢 |
| **HR_MANAGER** | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 vše | 🔴 | 🔴 |
| **HR_STAFF** | 🔴 | 🔴 | 🔴 | 🔴 | 🟡 bez mezd | 🔴 | 🔴 |
| **CFO** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 vše | 🔴 |
| **CEO** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟡 agregát | 🔴 |
| **ADMIN** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 systém |

---

### Co přesně každá role vidí

**TELLER** (Jana Nováková, Karel Dvořák)
- ✅ Základní info o svých přidělených klientech
- ✅ Stav účtu maskovaně (číslo účtu skryto)
- ✅ Transakce pouze svých klientů
- ❌ Rodné číslo, celá transakční historie, jiní klienti

**BRANCH_MANAGER** (Lucie Svobodová – Brno)
- ✅ Všichni klienti své pobočky
- ✅ Přehledy a reporty celé pobočky
- ✅ Výkon svého týmu
- ❌ Jiné pobočky, HR záznamy, mzdy

**REGIONAL_DIRECTOR** (Pavel Horák – Morava)
- ✅ Agregované přehledy celého regionu
- ✅ Výkon všech poboček v regionu
- ❌ Detailní data klientů, jiný region

**RISK_MANAGER** (Tomáš Veselý)
- ✅ Všechny transakce celé banky
- ✅ Fraud score, rizikové profily, scoring úvěrů
- ❌ Jméno klienta, číslo účtu, IBAN (vše maskováno)

**COMPLIANCE_OFFICER** (Alena Marková)
- ✅ KYC/AML status klientů
- ✅ Podezřelé transakce pro AML
- ✅ Plný přístup k audit logům
- ❌ Běžné transakce, zůstatky

**HR_MANAGER** (Jana Procházková)
- ✅ Kompletní záznamy všech zaměstnanců včetně mezd
- ❌ Jakákoliv klientská nebo finanční data

**HR_STAFF** (Marie Kratochvílová)
- ✅ Základní HR záznamy, docházka, kontakty
- ❌ Mzdy, bonusy, hodnocení výkonu

**CFO** (Martin Novák)
- ✅ Finanční výsledky celé banky, všechny pobočky
- ❌ Osobní data klientů ani zaměstnanců

**CEO** (Petra Horáčková)
- ✅ Agregované KPI a finanční přehledy
- ❌ Osobní data klientů, detailní záznamy zaměstnanců

---

### Testovací účty

| Email | Role | Umístění |
|---|---|---|
| jana.novakova@banka-morava.cz | TELLER | Brno centrum |
| lucie.svobodova@banka-morava.cz | BRANCH_MANAGER | Brno centrum |
| pavel.horak@banka-morava.cz | REGIONAL_DIRECTOR | Region Morava |
| tomas.vesely@banka-morava.cz | RISK_MANAGER | Ústředí |
| alena.markova@banka-morava.cz | COMPLIANCE_OFFICER | Ústředí |
| jana.prochazkova@banka-morava.cz | HR_MANAGER | Ústředí |
| marie.kratochvilova@banka-morava.cz | HR_STAFF | Ústředí |
| martin.novak@banka-morava.cz | CFO | Ústředí |
| petra.horackova@banka-morava.cz | CEO | Ústředí |

---

## Struktura projektu

```
virtual_co/
├── api/
│   ├── main.py                  # FastAPI backend
│   ├── cli.py                   # CLI klient s historií
│   ├── agent.py                 # Agent smyčka
│   ├── langflow_setup.py        # Vytvoří flow v Langflow
│   └── claude_cli_component.py  # Custom Langflow komponenta
└── db_demo/
    ├── schema.sql               # DDL – 13 tabulek
    ├── seed_banka_morava.sql    # Základní seed data
    ├── seed_rozsireni.sql       # HR Staff, nové role
    ├── seed_praha.sql           # Praha pobočky
    └── schema_grafika.md        # Mermaid diagramy
```

---

## Klíčový princip

> Access control musí proběhnout **před** tím, než LLM dostane data.

LLM není důvěryhodná entita — dostane jen bezpečná, filtrovaná, autorizovaná data.

---

## Tech stack

- **FastAPI** – backend, auth, RBAC
- **PostgreSQL** – databáze s access rules
- **Claude** – LLM přes `claude -p` (Max subscription)
- **Langflow** – orchestrace agent flow
- **uv** – Python package manager
- **Docker** – PostgreSQL + Langflow
