with orgs_ownership as (
/* 
On récupère les organisations et leurs propriétaires
On vérifie aussi si le mail de chaque propriétaire est "gouv"
*/
select o.id, o.name, l.email as "owners", l.email SIMILAR TO :'whitelist' as "gouv_owner"
from orgs o
left join acl_rules acl on o.id = acl.org_id
left join groups g on acl.group_id = g.id
left join group_users gu on g.id = gu.group_id
left join users u on gu.user_id = u.id
left join logins l on u.id = l.user_id 
where o.name <> 'Personal' and g.name = 'owners'
),

/*
On aggrège ces infos, en vérifiant si au moins un propriétaire de l'organisation est "gouv"
*/
orgs_agg as (
SELECT id, name, string_agg(owners, ',') as "owners", BOOL_OR(gouv_owner) as "gouv_owner"
FROM orgs_ownership
GROUP BY id, name
)

/*
On récupère les organisations qui n'ont pas de propriétaire "gouv"
*/
SELECT * FROM orgs_agg WHERE NOT gouv_owner;