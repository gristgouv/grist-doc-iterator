#!/usr/bin/env bash

# Retrieve arguments passed to the command

moved_suffix="__moved"

for i in "$@"; do
  case $i in
    -s=*|--src=*)
      src="${i#*=}"
      shift
      ;;
    -d=*|--dst=*)
      dst="${i#*=}"
      shift
      ;;
    --moved_suffix=*)
      moved_suffix="${i#*=}"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
done

echo_red() {
  echo -e "\033[0;31m$1\033[0m"
}

echo_green() {
  echo -e "\033[0;32m$1\033[0m"
}

if [ -z "$src" ] || [ -z "$dst" ]; then
  echo_red "Usage: $0 --src=... --dst=... [--moved_suffix=...]"
  exit 1
fi

cat_cmd=$(which bat batcat cat | head -n 1)
declare -a cat_cmd_args
if [[ $(basename "$cat_cmd") == "bat"* ]]; then
  cat_cmd_args+=("-l" "sql" "-p" "--paging=never")
fi

echo_red "Account $src will be deleted"
echo_green "Account $dst will receive the docs"
echo ""
read -p "Press enter to continue"
echo ""

$cat_cmd ${cat_cmd_args[@]} <<EOF
DROP TABLE IF EXISTS source_info;

CREATE TEMPORARY TABLE source_info as select u.id as user_id, w.id as workspace_id, o.id as org_id
from logins l join users u on u.id=l.user_id
  join orgs o on o.owner_id=u.id
  join workspaces w on w.org_id=o.id
where l.email='${src}' and o.name='Personal';

select * from source_info;

DROP VIEW IF EXISTS target_info;

CREATE TEMPORARY VIEW target_info as select u.id as user_id, o.id as org_id
from logins l join users u on u.id=l.user_id
  join orgs o on o.owner_id=u.id
  join acl_rules ar on ar.org_id=o.id
where l.email='${dst}' and o.name='Personal' and ar.permissions=63
LIMIT 1;

select * from target_info;

begin;

UPDATE workspaces set name=(name || '${moved_suffix}'), org_id=(SELECT t.org_id from target_info t) where id in (SELECT s.workspace_id from source_info s) returning *; -- Change workspace orgs and rename their name won't conflict with the target organization ones

WITH source_and_target_org_id_match as (
  select src_grp.id as src_grp_id, dst_grp.id as dst_grp_id
  from groups src_grp join groups dst_grp on src_grp.name=dst_grp.name
    join acl_rules src_ar on src_grp.id=src_ar.group_id
    join acl_rules dst_ar on dst_grp.id=dst_ar.group_id
  where src_ar.org_id=(select distinct(org_id) from source_info) and dst_ar.org_id=(select distinct(org_id) from target_info)
)
UPDATE group_groups
set subgroup_id=(select dst_grp_id from source_and_target_org_id_match where src_grp_id=subgroup_id)
where subgroup_id in (select src_grp_id from source_and_target_org_id_match) returning *; -- Make moved workspace inherit their rights from the target org

update group_users set user_id=(select distinct(user_id) from target_info)
where user_id=(select distinct(user_id) from source_info)
and not exists (select 1 from group_users gu where group_users.group_id=gu.group_id and gu.user_id=(select distinct(user_id) from target_info))
returning *; -- Remove every permissions of the old user and grant them to the new one, if not already existing

delete from group_users where user_id=(select distinct(user_id) from source_info) returning *; -- Remove the old user from the groups where the new user was already present

update docs set created_by=(select distinct(user_id) from target_info) where created_by=(select distinct(user_id) from source_info) returning *; -- Update the docs so they are marked as being created by the new account instead. FIXME: required? A good idea regarding the history?

UPDATE aliases set org_id=(select distinct(org_id) from target_info) where doc_id in (select d.id from docs d join source_info s on d.workspace_id=s.workspace_id) returning *; -- Update the org in the aliases.

-- Delete the old account
DELETE from acl_rules where acl_rules.org_id=(select id from orgs where orgs.owner_id=(select distinct(user_id) from source_info));
DELETE from logins where user_id=(select distinct(user_id) from source_info);
DELETE from orgs where owner_id=(select distinct(user_id) from source_info);
DELETE from users where id=(select distinct(user_id) from source_info);

commit;
EOF
