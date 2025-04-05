#! /usr/bin/bash

TIMESTAMP=$(date +%s)
GRIST_DIR="${1:-./}"
VARSFILE=/tmp/"$TIMESTAMP"grist_env_vars.txt
DESTFILE=/tmp/"$TIMESTAMP"undoc_grist_env_vars.txt

[ -f "$DESTFILE" ] && rm "$DESTFILE"

grep -rhoP 'process\.env\.[A-Z_]+' "$GRIST_DIR"/app \
| cut -d"." -f3 \
| sort -u \
>> "$VARSFILE"

while read -r ENV_VAR; do
    if ! grep -q "$ENV_VAR" "$GRIST_DIR"/README.md; then
        echo "$ENV_VAR" not documented | tee -a "$DESTFILE"
    fi
done < "$VARSFILE"
