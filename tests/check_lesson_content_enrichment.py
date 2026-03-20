#!/usr/bin/env python3
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
LESSON_FILES = sorted((ROOT / "DailySpeak" / "Resources").glob("s??_q*.json"))

MIN_CONTENT_MISTAKES = 4
MIN_LANGUAGE_MISTAKES = 4
MIN_UPGRADES_PER_SAMPLE = 4


def main() -> int:
    failures: list[str] = []

    if not LESSON_FILES:
        failures.append("No structured lesson files were found.")

    for path in LESSON_FILES:
        with path.open() as handle:
            data = json.load(handle)

        strategy = data.get("strategy", {})
        common_mistakes = strategy.get("common_mistakes", {})
        content_count = len(common_mistakes.get("content", []))
        language_count = len(common_mistakes.get("language", []))

        if content_count < MIN_CONTENT_MISTAKES:
            failures.append(
                f"{path.name}: content mistakes {content_count} < {MIN_CONTENT_MISTAKES}"
            )

        if language_count < MIN_LANGUAGE_MISTAKES:
            failures.append(
                f"{path.name}: language mistakes {language_count} < {MIN_LANGUAGE_MISTAKES}"
            )

        for index, sample in enumerate(data.get("samples", []), start=1):
            upgrade_count = len(sample.get("upgrades", []))
            if upgrade_count < MIN_UPGRADES_PER_SAMPLE:
                failures.append(
                    f"{path.name}: sample {index} upgrades {upgrade_count} < {MIN_UPGRADES_PER_SAMPLE}"
                )

    if failures:
        print("Lesson enrichment check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(
        f"Lesson enrichment check passed for {len(LESSON_FILES)} files "
        f"with thresholds content>={MIN_CONTENT_MISTAKES}, "
        f"language>={MIN_LANGUAGE_MISTAKES}, upgrades>={MIN_UPGRADES_PER_SAMPLE}."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
