# Audit Grist instance

**Status: ✅ Ready to be used in production**

Run some SQL scripts against the Grist home database in order to audit Grist usage by external users.
In the context of the French administration's instance, this means auditing users that are not public servants.

## Prerequisites

These queries were written for PostgreSQL and haven't been tested on sqlite.

You must provide a text file listing email domains you consider "internal" to your organisation in order for the quesries to work.

## To run it:

```
psql -U grist -d grist -v whitelist="$(cat whitelist.txt)" -f audit_orgs.sql
```
