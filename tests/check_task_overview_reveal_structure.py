#!/usr/bin/env python3

from pathlib import Path
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/TaskOverviewView.swift")


def require(text: str, needle: str, message: str) -> None:
    if needle not in text:
        print(f"FAIL: {message}")
        sys.exit(1)


def main() -> int:
    text = SOURCE.read_text()

    required = [
        ("enum OverviewPresentationPhase", "missing overview presentation phase enum"),
        ("case heroEntrance", "missing hero entrance phase"),
        ("case heroDockToTop", "missing dock-to-top phase"),
        ("case ready", "missing final ready phase"),
        ("enum OverviewStepDisplayState", "missing per-step display state enum"),
        ("case unlocked", "missing unlocked step state"),
        ("case locked", "missing locked step state"),
        ("@State private var showDockedHero = false", "missing docked hero visibility state"),
        ("@State private var showFocusSection = false", "missing focus visibility state"),
        ("@State private var showFlowSection = false", "missing flow visibility state"),
        ("runRevealSequence()", "missing reveal sequence runner"),
        ("runStepProgression()", "missing dedicated step progression runner"),
    ]

    for needle, message in required:
        require(text, needle, message)

    print("PASS: task overview reveal state machine structure is present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
