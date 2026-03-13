#!/usr/bin/env python3

from pathlib import Path
import sys


SOURCE = Path("/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/CourseData.swift")


def main() -> int:
    text = SOURCE.read_text()

    bad = 'case .vocabulary:  "textbook"'
    good = 'case .vocabulary:  "character.book.closed.fill"'

    if bad in text:
        print("FAIL: vocabulary step still uses the invalid textbook symbol")
        return 1

    if good not in text:
        print("FAIL: vocabulary step should use character.book.closed.fill")
        return 1

    print("PASS: vocabulary step uses a valid icon")
    return 0


if __name__ == "__main__":
    sys.exit(main())
