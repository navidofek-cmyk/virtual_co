"""
Custom Langflow komponenta – volá Claude přes CLI (claude -p).
Nevyžaduje API klíč, používá Max subscripci.

Jak přidat do Langflow:
1. Otevři http://localhost:7860
2. Klikni na + New Flow
3. Klikni na Custom Component
4. Vlož tento kód
"""
import subprocess
from langflow.custom import Component
from langflow.io import MessageTextInput, Output
from langflow.schema.message import Message


class ClaudeCLI(Component):
    display_name = "Claude CLI"
    description  = "Volá Claude přes CLI (claude -p). Nevyžaduje API klíč."
    icon         = "terminal"

    inputs = [
        MessageTextInput(
            name="input_value",
            display_name="Prompt",
            info="Celý prompt včetně kontextu uživatele a dat.",
        ),
    ]

    outputs = [
        Output(
            display_name="Odpověď",
            name="text_output",
            method="build_output",
        ),
    ]

    def build_output(self) -> Message:
        prompt = self.input_value

        result = subprocess.run(
            ["claude", "-p", prompt],
            capture_output=True,
            text=True,
            timeout=60,
        )

        text = result.stdout.strip() or result.stderr.strip() or "Žádná odpověď."
        self.status = text
        return Message(text=text)
