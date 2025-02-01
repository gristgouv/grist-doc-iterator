#!/usr/bin/env bash

set -euo pipefail

echo_err() {
  echo -e "\e[31mERROR: $1\e[0m" >&2
}

echo_success() {
  echo -e "\e[32m SUCCESS!\e[0m"
}

echo_fail() {
  echo -e "\e[31m FAIL!\e[0m"
  exit 1
}

check_result() {
  if [ $1 ]; then
    echo_success
  else
    echo_fail
  fi
}

if [ ! -x $(which mc) ]; then
  echo_err "mc not found"
fi

alias="${MC_ALIAS:-prod-grist}"
prod_bucket="${PROD_BUCKET:-donnees-grist-production-snapshots}"
backup_bucket="$prod_bucket-backup"
db_backup_bucket="${prod_bucket/snapshots/db-backups/}"
minimal_objects_expected=100
latest_glacier_date=$(date --date="-3days" --iso-8601)
today=$(date --iso-8601)
today_folder=$(mc ls --json $alias/$backup_bucket/backup/ | jq -r '.key | rtrimstr("/")' | grep "^${today}")
latest_glacier_folder=$(mc ls --json $alias/$backup_bucket/backup/ | jq -r '.key | rtrimstr("/")' | grep "^${latest_glacier_date}")

check_backup_bucket_exist() {
  echo -n "Check that backup bucket exist:"
  local status=$(mc ls --json $alias/$backup_bucket | jq -r ".status")
  check_result "'$status' == 'success'"
}

check_today_folder_exist() {
  echo -n "Check that today folder exist:"
  check_result "-n '$today'"
}

check_latest_glacier_folder() {
  echo -n "Check that latest glacier folder exist:"
  check_result "-n '$latest_glacier_folder'"

  echo -n "Check that this folder contain objects:"
  local content=$(mc ls --json "$alias/$backup_bucket/backup/$latest_glacier_folder/docs")
  local keys_count=$(echo "$content" | jq -r ".key" | wc -l)
  check_result "$keys_count -gt $minimal_objects_expected"

  echo -n "Check that this folder contain only objects stored in glacier:"
  local glacier_count=$(echo "$content" | jq -r ".storageClass" | wc -l)
  check_result "$glacier_count -eq $keys_count"

  echo "Number of objects in the latest backup in glacier: $glacier_count"
}

check_today_folder_objects() {
  echo -n "Check that the latest backup folder contain objects:"
  local tmp_dir=$(mktemp -d)
  local backup_content=$(mc ls --json "$alias/$backup_bucket/backup/$today_folder/docs" | jq -r ".key" | tee "$tmp_dir/backup.txt")
  local backup_keys_count=$(echo "$backup_content" | wc -l)
  check_result "$backup_keys_count -gt $minimal_objects_expected"

  echo "Compare differences between today backup and existing objects (diff result):"
  echo "press enter to continue..."
  read
  local prod_content=$(mc ls --json "$alias/$prod_bucket/docs" | jq -r ".key" | tee "$tmp_dir/prod.txt")
  diff -u "$tmp_dir/backup.txt" "$tmp_dir/prod.txt"
}

check_db_backup() {
  echo -n "Check that the DB backup bucket exist:"
  local folder_json=$(mc ls --json $alias/$db_backup_bucket)
  local status=$(echo $folder_json | jq -r ".status")
  check_result "'$status' == 'success'"
  echo -n "Check that the DB backup bucket has been modified today:"
  local last_modified_is_today=$(echo $folder_json | jq -r ".lastModified | startswith(\"$today\")")
  check_result "'$last_modified_is_today' == 'true'"
}

check_db_backup
check_backup_bucket_exist
check_latest_glacier_folder
check_today_folder_exist
check_today_folder_objects
