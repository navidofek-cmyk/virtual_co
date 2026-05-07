# Grafická schémata – Private AI Agent Platform

---

## 1. Celková architektura

```mermaid
graph TD
    U([👤 Uživatel]) --> CLI[CLI / Browser]
    CLI --> API[FastAPI Backend]

    API --> AUTH{Autentizace}
    AUTH -->|❌ zamítnut| ERR1[401 Unauthorized]
    AUTH -->|✅ ok| RBAC{RBAC kontrola}

    RBAC -->|❌ nemá právo| ERR2[403 Forbidden]
    RBAC -->|✅ ok| FILTER[Filtrování dat]

    FILTER --> AGENT[Agent smyčka]
    AGENT --> CLAUDE["🤖 Claude (claude -p)"]
    CLAUDE --> AGENT

    AGENT --> LOG[(audit_logs)]
    AGENT --> HIST[(agent_runs)]
    AGENT --> U
```

---

## 2. Agent smyčka

```mermaid
sequenceDiagram
    participant U as Uživatel
    participant F as FastAPI
    participant A as Agent
    participant C as Claude CLI
    participant T as Nástroje

    U->>F: "Porovnej transakce a klienty"
    F->>F: Ověř uživatele + práva
    F->>A: dotaz + dostupné nástroje

    A->>C: claude -p "Co potřebuješ zavolat?"
    C-->>A: ["get_transactions", "get_clients"]

    A->>T: volej get_transactions()
    T-->>A: 247 transakcí, 4.2M Kč

    A->>T: volej get_clients()
    T-->>A: ❌ Přístup zamítnut

    A->>C: claude -p "Odpověz s těmito daty"
    C-->>A: "Transakce: 247... Klienti: přístup zamítnut"

    A-->>F: odpověď
    F->>F: ulož do agent_runs
    F-->>U: odpověď
```

---

## 3. Přístupová kontrola

```mermaid
flowchart LR
    REQ([Dotaz]) --> A1{Má JWT token?}
    A1 -->|ne| E1[❌ 401]
    A1 -->|ano| A2{Má agents.run?}
    A2 -->|ne| E2[❌ 403]
    A2 -->|ano| A3{Má pravidlo\npro data source?}
    A3 -->|ne| E3[❌ Přístup zamítnut]
    A3 -->|ano| A4[Aplikuj row_filter\na column_filter]
    A4 --> A5[Filtrovaná data\n→ Claude]
    A5 --> A6[(audit_log)]
    A5 --> RES([✅ Odpověď])
```

---

## 4. Databázové schéma – podrobné

```mermaid
erDiagram
    organizations ||--o{ departments      : "má oddělení"
    organizations ||--o{ users            : "má uživatele"
    organizations ||--o{ agents           : "má agenty"
    organizations ||--o{ data_sources     : "má zdroje dat"
    organizations ||--o{ data_access_rules: "má přístupová pravidla"
    organizations ||--o{ conversations    : "má konverzace"
    organizations ||--o{ audit_logs       : "má audit logy"

    departments   ||--o{ users            : "obsahuje"

    users         ||--o{ user_roles       : "má role"
    users         ||--o{ conversations    : "vede"
    users         ||--o{ agent_runs       : "spouští"
    users         ||--o{ audit_logs       : "generuje"

    roles         ||--o{ user_roles       : "přiřazena uživatelům"
    roles         ||--o{ role_permissions : "má oprávnění"
    roles         ||--o{ data_access_rules: "řídí přístup"

    permissions   ||--o{ role_permissions : "patří rolím"

    agents        ||--o{ conversations    : "obsluhuje"
    agents        ||--o{ agent_runs       : "spouští"

    conversations ||--o{ agent_runs       : "obsahuje zprávy"

    data_sources  ||--o{ data_access_rules: "chráněno pravidly"

    agent_runs    ||--o{ agent_run_steps  : "má kroky"

    organizations {
        text      id         PK
        text      name       "Banka Morava a.s."
        text      slug       UK "banka-morava"
        timestamp created_at
    }

    departments {
        text id              PK
        text organization_id FK
        text name            "HR, Finance, Retail..."
    }

    users {
        text    id              PK
        text    organization_id FK
        text    department_id   FK
        text    email           UK
        text    full_name
        text    branch_id       "brno-centrum, praha-smichov..."
        text    region_id       "morava, cechy"
        boolean is_active
        timestamp created_at
    }

    roles {
        text id          PK
        text name        UK "TELLER, MANAGER, CEO..."
        text description
    }

    permissions {
        text id          PK
        text code        UK "agents.run, hr.read..."
        text description
    }

    user_roles {
        text user_id FK
        text role_id FK
    }

    role_permissions {
        text role_id       FK
        text permission_id FK
    }

    agents {
        text    id              PK
        text    organization_id FK
        text    name            "FinanceBot"
        text    description
        text    system_prompt
        boolean is_active
        timestamp created_at
    }

    data_sources {
        text    id              PK
        text    organization_id FK
        text    name
        text    type            "postgresql, sharepoint, pdf..."
        boolean is_active
        timestamp created_at
    }

    data_access_rules {
        text    id              PK
        text    organization_id FK
        text    subject_type    "user nebo role"
        text    subject_id      FK
        text    resource_type   "data_source"
        text    resource_id     FK
        text    access_level    "read, write, none"
        jsonb   row_filter      "{branch_id: brno-centrum}"
        jsonb   column_filter   "{exclude: [salary, iban]}"
        int     priority        "vyšší = silnější"
        timestamp created_at
    }

    conversations {
        text      id              PK
        text      organization_id FK
        text      user_id         FK
        text      agent_id        FK
        text      title
        timestamp created_at
    }

    agent_runs {
        text      id              PK
        text      conversation_id FK
        text      user_id         FK
        text      agent_id        FK
        text      question
        text      answer
        text      status          "completed, error"
        timestamp created_at
    }

    agent_run_steps {
        text      id           PK
        text      agent_run_id FK
        int       step_order
        text      step_type    "tool_call, llm_call"
        text      tool_name    "get_transactions..."
        jsonb     input
        jsonb     output
        timestamp created_at
    }

    audit_logs {
        text      id              PK
        text      organization_id FK
        text      user_id         FK
        text      action          "agent_query, login..."
        text      entity_type     "conversation, agent"
        text      entity_id       FK
        jsonb     details         "prompt, role, accessible..."
        timestamp created_at
    }
```

---

## 5. Kdo co vidí

```mermaid
graph LR
    subgraph Ústředí
        CEO --> F[💰 Finance agregát]
        CFO --> F
        HR --> H[👥 HR záznamy]
        HR_S[HR Staff] --> H2[👥 HR bez mezd]
        CMP[Compliance] --> AL[📋 Audit logy]
        RSK[Risk] --> TX_ALL[📊 Transakce\nvšechny bez PII]
    end

    subgraph Region Morava
        RD[Reg. ředitel] --> TX_REG[📊 Transakce\nMorava]
    end

    subgraph Pobočka Brno
        MGR[Manager] --> TX_BR[📊 Transakce\nBrno]
        MGR --> CL_BR[👤 Klienti\nBrno]
        TEL[Teller] --> TX_OWN[📊 Vlastní\nklienti]
    end
```

---

## 6. Soubory projektu

```mermaid
graph TD
    subgraph db_demo
        S[schema.sql]
        SD[seed_banka_morava.sql]
        SR[seed_rozsireni.sql]
        SP[seed_praha.sql]
    end

    subgraph api
        M[main.py\nFastAPI]
        C[cli.py\nCLI klient]
        AG[agent.py\nAgent smyčka]
        LS[langflow_setup.py]
        CC[claude_cli_component.py]
        CF[config.json]
    end

    subgraph Docker
        PG[(PostgreSQL\nport 5432)]
        LF[Langflow\nport 7860]
    end

    S --> PG
    SD --> PG
    SR --> PG
    SP --> PG

    C --> M
    AG --> M
    M --> PG
    M --> CC
    LS --> LF
    CC --> LF
```
