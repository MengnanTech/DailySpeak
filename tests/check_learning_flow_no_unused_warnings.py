#!/usr/bin/env python3

from pathlib import Path
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift")


def main() -> int:
    text = SOURCE.read_text()

    forbidden = [
        "let canAdvance = isCurrentCompleted || currentStep < steps.count - 1",
        "let nextIsLocked = !isLastStep && !isStepUnlocked(currentStep + 1)",
    ]

    for item in forbidden:
        if item in text:
            print(f"FAIL: found unused warning source: {item}")
            return 1

    print("PASS: unused warning variables were removed from LearningFlowView")
    return 0


if __name__ == "__main__":
    sys.exit(main())
