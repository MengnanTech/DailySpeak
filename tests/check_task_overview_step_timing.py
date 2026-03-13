#!/usr/bin/env python3

from pathlib import Path
import re
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/TaskOverviewView.swift")


def main() -> int:
    text = SOURCE.read_text()
    match = re.search(r"private func startStepSequence\(\) \{(?P<body>.*?)\n    \}", text, re.S)
    if not match:
        print("Could not find startStepSequence()")
        return 1

    body = match.group("body")

    if "task.tips" in body or "totalTipsDuration" in body:
        print("FAIL: step sequence is still gated by tips animation")
        return 1

    if "animateStep(at: 0, afterDelay: 0.2)" not in body:
        print("FAIL: expected first step to start with a short fixed delay")
        return 1

    print("PASS: first overview step is no longer delayed by tips animation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
