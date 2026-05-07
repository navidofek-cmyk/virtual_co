# Visual Diagrams – Private AI Agent Platform

---

## 1. Overall Architecture

```mermaid
graph TD
    U([👤 User]) --> CLI[CLI / Browser]
    CLI --> API[FastAPI Backend]

    API --> AUTH{Authentication}
    AUTH -->|❌ rejected| ERR1[401 Unauthorized]
    AUTH -->|✅ ok| RBAC{RBAC check}

    RBAC -->|❌ no permission| ERR2[403 Forbidden]
    RBAC -->|✅ ok| FILTER[Data Filtering]

    FILTER --> AGENT[Agent loop]
    AGENT --> CLAUDE["🤖 Claude (claude -p)"]
    CLAUDE --> AGENT

    AGENT --> LOG[(audit_logs)]
    AGENT --> HIST[(agent_runs)]
    AGENT --> U
```

---

## 2. Agent Loop

```mermaid
sequenceDiagram
    participant U as User
    participant F as FastAPI
    participant A as Agent
    participant C as Claude CLI
    participant T as Tools

    U->>F: "Compare transactions and clients"
    F->>F: Verify user + permissions
    F->>A: query + available tools

    A->>C: claude -p "What do you need to call?"
    C-->>A: ["get_transactions", "get_clients"]

    A->>T: call get_transactions()
    T-->>A: 247 transactions, 4.2M CZK

    A->>T: call get_clients()
    T-->>A: ❌ Access denied

    A->>C: claude -p "Respond with this data"
    C-->>A: "Transactions: 247... Clients: access denied"

    A-->>F: response
    F->>F: save to agent_runs
    F-->>U: response
```

---

## 3. Access Control

```mermaid
flowchart LR
    REQ([Query]) --> A1{Has JWT token?}
    A1 -->|no| E1[❌ 401]
    A1 -->|yes| A2{Has agents.run?}
    A2 -->|no| E2[❌ 403]
    A2 -->|yes| A3{Has rule\nfor data source?}
    A3 -->|no| E3[❌ Access denied]
    A3 -->|yes| A4[Apply row_filter\nand column_filter]
    A4 --> A5[Filtered data\n→ Claude]
    A5 --> A6[(audit_log)]
    A5 --> RES([✅ Response])
```

---

## 4. Database Schema – Detailed

```mermaid
erDiagram
    organizations ||--o{ departments      : "has departments"
    organizations ||--o{ users            : "has users"
    organizations ||--o{ agents           : "has agents"
    organizations ||--o{ data_sources     : "has data sources"
    organizations ||--o{ data_access_rules: "has access rules"
    organizations ||--o{ conversations    : "has conversations"
    organizations ||--o{ audit_logs       : "has audit logs"

    departments   ||--o{ users            : "contains"

    users         ||--o{ user_roles       : "has roles"
    users         ||--o{ conversations    : "conducts"
    users         ||--o{ agent_runs       : "triggers"
    users         ||--o{ audit_logs       : "generates"

    roles         ||--o{ user_roles       : "assigned to users"
    roles         ||--o{ role_permissions : "has permissions"
    roles         ||--o{ data_access_rules: "controls access"

    permissions   ||--o{ role_permissions : "belongs to roles"

    agents        ||--o{ conversations    : "serves"
    agents        ||--o{ agent_runs       : "triggers"

    conversations ||--o{ agent_runs       : "contains messages"

    data_sources  ||--o{ data_access_rules: "protected by rules"

    agent_runs    ||--o{ agent_run_steps  : "has steps"

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
        text    subject_type    "user or role"
        text    subject_id      FK
        text    resource_type   "data_source"
        text    resource_id     FK
        text    access_level    "read, write, none"
        jsonb   row_filter      "{branch_id: brno-centrum}"
        jsonb   column_filter   "{exclude: [salary, iban]}"
        int     priority        "higher = stronger"
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

## 5. Who Sees What

```mermaid
graph LR
    subgraph Headquarters
        CEO --> F[💰 Finance aggregate]
        CFO --> F
        HR --> H[👥 HR records]
        HR_S[HR Staff] --> H2[👥 HR without salaries]
        CMP[Compliance] --> AL[📋 Audit logs]
        RSK[Risk] --> TX_ALL[📊 Transactions\nall without PII]
    end

    subgraph Region Moravia
        RD[Regional director] --> TX_REG[📊 Transactions\nMoravia]
    end

    subgraph Branch Brno
        MGR[Manager] --> TX_BR[📊 Transactions\nBrno]
        MGR --> CL_BR[👤 Clients\nBrno]
        TEL[Teller] --> TX_OWN[📊 Own\nclients]
    end
```

---

## 6. Project Files

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
        C[cli.py\nCLI client]
        AG[agent.py\nAgent loop]
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
