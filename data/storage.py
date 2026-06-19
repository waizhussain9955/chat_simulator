"""
data/storage.py
---------------
JSON-based conversation persistence.
Handles save, load, and validation of conversation data.
"""

import json
import os
from typing import List, Dict


class ConversationStorage:
    """Load and save conversation pairs to/from JSON files."""

    # ── schema ──────────────────────────────────────────────────────────
    REQUIRED_KEYS = {"message", "reply"}

    # ── public API ───────────────────────────────────────────────────────

    @staticmethod
    def save(conversations: List[Dict[str, str]], filepath: str) -> None:
        """
        Persist *conversations* to *filepath* as pretty-printed JSON.

        Raises:
            ValueError  – if data validation fails
            IOError     – if the file cannot be written
        """
        ConversationStorage._validate(conversations)
        with open(filepath, "w", encoding="utf-8") as fh:
            json.dump(conversations, fh, ensure_ascii=False, indent=2)

    @staticmethod
    def load(filepath: str) -> List[Dict[str, str]]:
        """
        Read conversations from *filepath*.

        Raises:
            FileNotFoundError – if *filepath* doesn't exist
            ValueError        – if JSON is malformed or schema invalid
        """
        if not os.path.isfile(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")

        with open(filepath, "r", encoding="utf-8") as fh:
            try:
                data = json.load(fh)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON: {exc}") from exc

        ConversationStorage._validate(data)
        return data

    # ── private helpers ──────────────────────────────────────────────────

    @staticmethod
    def _validate(data) -> None:
        if not isinstance(data, list):
            raise ValueError("Conversations must be a JSON array.")
        for i, item in enumerate(data):
            if not isinstance(item, dict):
                raise ValueError(f"Item {i} is not an object.")
            for key in ConversationStorage.REQUIRED_KEYS:
                if key not in item:
                    raise ValueError(f"Item {i} is missing key '{key}'.")
                if not isinstance(item[key], str):
                    raise ValueError(f"Item {i}['{key}'] must be a string.")
