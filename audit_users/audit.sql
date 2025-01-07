\x

/*
On récupère la liste des utilisateurs :
- avec un domaine mail potentiellement d'externe
- qui se sont déjà connectés à grist
*/
WITH non_gouv_users AS (
select l.email, u.id, u.last_connection_at 
from logins l
left join users u on l.user_id = u.id
where l.email NOT SIMILAR TO :'whitelist'
and first_login_at is not null
),

/*
On récupère ensuite la liste des utilisateurs et le détails des organisations dont ils font partie
On vérifie si les utilisateurs n'ont qu'une seule organisation (par définition, leur espace Personnel)
*/
externes AS (
SELECT ngu.email, MAX(ngu.last_connection_at) as "last_login", MAX(o.id) as "org_id", count(o.name)=1 as "single_org_user", string_agg(o.name, ',') as "organisations", string_agg(l.email, ',') as "organisation_owners"
FROM non_gouv_users ngu
LEFT JOIN group_users gu on ngu.id = gu.user_id
LEFT JOIN groups g on gu.group_id = g.id
LEFT JOIN acl_rules acl on g.id = acl.group_id
LEFT JOIN orgs o on acl.org_id = o.id
LEFT JOIN users u on o.owner_id = u.id
LEFT JOIN logins l on u.id = l.user_id
GROUP BY ngu.email
),

/*
On filtre les utilisateurs qui ne sont membres que de leur espace personnel
*/
single_org_users AS (
SELECT * FROM externes WHERE single_org_user
)

/*
On récupère les documents de l'espace personnel des utilisateurs
*/
SELECT sou.email, sou.last_login, sou.org_id, ws.name, ws.id, d.name, d.id, d.usage
FROM single_org_users sou
LEFT JOIN workspaces ws on sou.org_id = ws.org_id
LEFT JOIN docs d on ws.id = d.workspace_id
WHERE d.id is not null
