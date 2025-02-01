#!/usr/bin/env bash

echo_err() {
  echo -e "\033[31m${1}\033[0m"
}

prerequisites=("sqlite3" "python3" "xxd")
for prereq in "${prerequisites[@]}"; do
  if [ ! -x "$(which "${prereq}")" ]; then
    echo_err "You need to install ${prereq} first"
    exit 1
  fi
done

grist="$1"
if [ -z "$grist" ]; then
  echo_err "Usage: ${0} /path/to/file.grist"
  exit 1
fi

if [ ! -r "$grist" ]; then
  echo_err "Error: ${grist} does not exist or you do not have the permission to read it"
  exit 1
fi

unmarshal_py_cmd=$(cat <<EOF
import marshal
import json

with open('/dev/stdin', 'rb') as f:
  while(True):
    try:
      res = marshal.load(f)
    except EOFError as e:
      break
    if not res:
      break
    print(json.dumps(res))
EOF
)

sqlite3 "$grist" "select hex(body) from _gristsys_ActionHistory order by id desc" | xxd -r -p | python3 -c "$unmarshal_py_cmd"
