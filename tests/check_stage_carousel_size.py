#!/usr/bin/env python3

from pathlib import Path
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/StageListView.swift")


def require(text: str, needle: str, message: str) -> None:
    if needle not in text:
        print(f"FAIL: {message}")
        sys.exit(1)


def main() -> int:
    text = SOURCE.read_text()

    require(
        text,
        'let sidePeek = min(24, max(12, geo.size.width * 0.06))',
        "stage carousel should use a near-original side peek",
    )
    require(
        text,
        'let itemSpacing: CGFloat = min(10, max(6, geo.size.width * 0.018))',
        "stage carousel should keep moderate spacing",
    )
    require(
        text,
        'let cardWidth = max(0, geo.size.width - sidePeek * 2)',
        "stage carousel width should no longer subtract extra spacing",
    )
    require(
        text,
        '.frame(height: 286)',
        "stage carousel height should stay close to the original size",
    )

    print("PASS: stage carousel keeps pseudo-3D effect with near-original sizing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
