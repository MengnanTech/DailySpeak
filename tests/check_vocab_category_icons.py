#!/usr/bin/env python3

from pathlib import Path
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift")


def require(text: str, needle: str, message: str) -> None:
    if needle not in text:
        print(f"FAIL: {message}")
        sys.exit(1)


def main() -> int:
    text = SOURCE.read_text()

    require(text, "var icon: String {", "VocabCategory should define an icon")
    require(text, 'case .core: "textbook.fill"', "core vocabulary should map to textbook.fill")
    require(text, 'case .extended: "sparkles"', "extended vocabulary should map to sparkles")
    require(text, 'Image(systemName: category.icon)', "category switcher should render the category icon")

    print("PASS: vocabulary categories expose and render icons")
    return 0


if __name__ == "__main__":
    sys.exit(main())
