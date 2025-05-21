#!/usr/bin/env bash

set -eEuo pipefail

PROJECT_ID=1
OWNER_NAME=gristlabs

item_count=$(gh project view $PROJECT_ID --owner $OWNER_NAME -q '.items.totalCount' --format json)
done=$(gh project item-list $PROJECT_ID --owner $OWNER_NAME --format json -L "$item_count" -q ".items[] | select(.status == \"Done\")" | jq -c '{"title": .title, "id": .id}')
done_ids=$(echo "$done" | jq -r ".id")

echo "Items to archive:"
echo "$done" | jq -r '"- " + .title'
echo ""

read -r -p "Proceed? [y/N] " continue
if [ "${continue,,}" != 'y' ]; then
  echo "exiting"
  exit 0
fi


for id in $done_ids; do
  echo "Archiving item $id..."
  gh project item-archive $PROJECT_ID --owner $OWNER_NAME --id "$id"
done

