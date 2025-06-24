#!/usr/bin/env bash

set -eEuo pipefail

GRIST_FILE="$1"
DESTINATION=/tmp/widgets.csv

# Add headers only if the destination is missing
MAYBE_HEADER_OPT=""
if [ ! -f "$DESTINATION" ] || [ "$(stat --printf="%s" "$DESTINATION")" -eq 0 ]; then
  MAYBE_HEADER_OPT="-header"
fi
if [ ! -f "$GRIST_FILE" ]; then
  echo "❌ File not found: $GRIST_FILE"
  exit 1
fi
filename=$(basename "$GRIST_FILE")

$SQLITE3 $MAYBE_HEADER_OPT -csv "$GRIST_FILE" 'select "'"${filename%.grist}"'" as ID, options->>"customView"->>"widgetId" as widgetID, options->>"customView"->>"url" as customURL from _grist_Views_section where options is not null and options <> '\'\'';' >> "$DESTINATION"
