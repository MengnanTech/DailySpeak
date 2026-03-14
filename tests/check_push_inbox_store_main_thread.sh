#!/usr/bin/env bash
set -euo pipefail

FILE="/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/PushInboxStore.swift"

echo "Checking push inbox update notification is dispatched on the main actor..."
rg -q '^actor PushInboxStore \{$' "$FILE"
if rg -q '^@MainActor$' "$FILE"; then
  echo "FAIL: PushInboxStore cannot be annotated with @MainActor because actors cannot have a global actor" >&2
  exit 1
fi
rg -q 'Task \{ @MainActor in' "$FILE"
rg -q 'NotificationCenter\.default\.post\(name: \.pushInboxDidUpdate, object: nil\)' "$FILE"
echo "PASS: PushInboxStore stays actor-isolated and dispatches update notifications on the main actor"
