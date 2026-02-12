#!/usr/bin/env bash

set -eEuo pipefail
set -x

GRIST_FILE="$1"
DESTINATION=/tmp/integrity.csv

# Add headers only if the destination is missing
if [ ! -f "$DESTINATION" ] || [ "$(stat -c %s "$DESTINATION")" -eq 0 ]; then
  echo 'doc,integrity' > $DESTINATION
fi
if [ ! -f "$GRIST_FILE" ]; then
  echo "❌ File not found: $GRIST_FILE"
  exit 1
fi
filename=$(basename "$GRIST_FILE")

cat << EOF >> $DESTINATION
${GRIST_FILE},$($SQLITE3 "${GRIST_FILE}" "PRAGMA integrity_check;")
EOF

