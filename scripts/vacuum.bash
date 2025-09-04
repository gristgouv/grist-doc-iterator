#!/usr/bin/env bash

set -eEuo pipefail

GRIST_FILE="$1"
VACUUMED="${GRIST_FILE%.grist}-vacuumed.grist"

if [ ! -f "$GRIST_FILE" ]; then
  echo "❌ File not found: $GRIST_FILE"
  exit 1
fi
if [ -f "$VACUUMED" ]; then
  echo "❌ File exists: $VACUUMED"
  exit 1
fi

cleanup() {
  [ -f "$VACUUMED" ] && shred -zu "$VACUUMED"
}

trap "cleanup" EXIT

$SQLITE3 "$GRIST_FILE" "vacuum into '$VACUUMED'"

orig_size=$(stat -c %s "$GRIST_FILE")
new_size=$(stat -c %s "$VACUUMED")

# If the new size is considerably lighter
if [ "$(bc -l <<< "$new_size < $orig_size * 0.9")" -eq 1 ]; then
  mv "$VACUUMED" "$GRIST_FILE"
fi
