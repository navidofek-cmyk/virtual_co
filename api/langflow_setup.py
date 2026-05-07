#!/usr/bin/env python3
"""
Vytvoří FinanceBot flow v Langflow s custom ClaudeCLI komponentou.
Použití: uv run python langflow_setup.py
"""
import httpx
import json

LANGFLOW_URL = "http://localhost:7860"
LF_KEY       = "sk-LCfLf13-iC-VzbHYtDIPW4W9h-Kbl6Hu-gJ7RvQCZbI"
CONFIG_FILE  = "config.json"

# Kód custom komponenty
CLAUDE_CLI_CODE = open("claude_cli_component.py").read()

FLOW = {
    "name": "FinanceBot",
    "description": "Bankovní AI agent – FastAPI → Langflow → Claude CLI",
    "data": {
        "nodes": [
            {
                "id": "TextInput-1",
                "type": "genericNode",
                "position": {"x": 50, "y": 200},
                "data": {
                    "type": "TextInput",
                    "id": "TextInput-1",
                    "display_name": "Prompt od FastAPI",
                    "node": {
                        "display_name": "Text Input",
                        "template": {
                            "_type": "Component",
                            "input_value": {
                                "display_name": "Text",
                                "field_type": "str",
                                "value": "",
                            }
                        },
                        "outputs": [
                            {"name": "text", "display_name": "Text", "types": ["Message"]}
                        ]
                    }
                }
            },
            {
                "id": "ClaudeCLI-1",
                "type": "genericNode",
                "position": {"x": 500, "y": 200},
                "data": {
                    "type": "CustomComponent",
                    "id": "ClaudeCLI-1",
                    "display_name": "Claude CLI",
                    "node": {
                        "display_name": "Claude CLI",
                        "description": "Volá Claude přes CLI – bez API klíče",
                        "template": {
                            "_type": "Component",
                            "code": {
                                "display_name": "Code",
                                "field_type": "code",
                                "value": CLAUDE_CLI_CODE,
                            },
                            "input_value": {
                                "display_name": "Prompt",
                                "field_type": "str",
                                "value": "",
                            }
                        },
                        "outputs": [
                            {"name": "text_output", "display_name": "Odpověď", "types": ["Message"]}
                        ]
                    }
                }
            },
            {
                "id": "TextOutput-1",
                "type": "genericNode",
                "position": {"x": 950, "y": 200},
                "data": {
                    "type": "TextOutput",
                    "id": "TextOutput-1",
                    "display_name": "Odpověď pro FastAPI",
                    "node": {
                        "display_name": "Text Output",
                        "template": {
                            "_type": "Component",
                            "input_value": {
                                "display_name": "Text",
                                "field_type": "str",
                                "value": ""
                            }
                        },
                        "outputs": [
                            {"name": "text", "display_name": "Text", "types": ["Message"]}
                        ]
                    }
                }
            }
        ],
        "edges": [
            {
                "id": "edge-1",
                "source": "TextInput-1",
                "target": "ClaudeCLI-1",
                "sourceHandle": "TextInput-1|text|0",
                "targetHandle": "ClaudeCLI-1|input_value|0",
            },
            {
                "id": "edge-2",
                "source": "ClaudeCLI-1",
                "target": "TextOutput-1",
                "sourceHandle": "ClaudeCLI-1|text_output|0",
                "targetHandle": "TextOutput-1|input_value|0",
            }
        ],
        "viewport": {"x": 0, "y": 0, "zoom": 1}
    }
}


def main():
    headers = {"x-api-key": LF_KEY}

    print("Připojuji se k Langflow...")
    r = httpx.get(f"{LANGFLOW_URL}/api/v1/flows/", headers=headers)
    flows = r.json()

    # Smaž staré FinanceBot flow
    for f in flows:
        if f["name"] == "FinanceBot":
            httpx.delete(f"{LANGFLOW_URL}/api/v1/flows/{f['id']}", headers=headers)
            print(f"Smazán starý flow: {f['id']}")

    print("Vytvářím flow s Claude CLI komponentou...")
    r = httpx.post(f"{LANGFLOW_URL}/api/v1/flows/", json=FLOW, headers=headers)
    if r.status_code not in (200, 201):
        print(f"Chyba: {r.status_code} {r.text[:300]}")
        return

    flow_id = r.json()["id"]
    print(f"Flow vytvořen: {flow_id}")

    config = {"flow_id": flow_id, "langflow_url": LANGFLOW_URL, "lf_key": LF_KEY}
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)
    print(f"Uloženo do {CONFIG_FILE}")
    print(f"\nFlow:")
    print(f"  TextInput → ClaudeCLI (claude -p) → TextOutput")
    print(f"\nSpusť: uv run uvicorn main:app --port 8000")


if __name__ == "__main__":
    main()
