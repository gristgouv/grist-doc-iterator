# Audit Grist instance

To run : 

```
psql -U grist -d grist -v whitelist="$(cat whitelist.txt)" -f audit_orgs.sql
```
