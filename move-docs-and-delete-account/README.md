# gen-sql-move-docs-and-delete-account

**Status: 🧪 Experimental**

**Notes**: 
- Used for a user in production once with success and using Postgresql, but not tested against a Sqlite3 database. Also there are some fragile assumptions (like the name of the personal workspace). 
- ALSO BE AWARE THAT THIS IS A DESTRUCTIVE SCRIPT (IT DELETES AN ACCOUNT PERMANENTLY).

## Description

⚠️  This script supposes you use a Postgresql database. It will probably work on Sqlite, but be cautious and test by your own before using it for that database.

Scenario: a user changed their email address and already landed to grist with their new email address.
Then the new account and the old account exist.

This main ideas of the script does the following (check the comments of the script for the details):
 - move every workspace of their personal org to the new one;
 - change every permission previously granted to the old account so they are granted to the new one;
 - and finally delete the old account;

## Usage

```bash
./gen-sql-move-docs-and-delete-account.bash --src=... --dst=... [--moved_suffix=...]
```

Where:
 - `--src` is the **normalized** email of the account which will be deleted
 - `--dst` is the **normalized** email of the account which will receive the workspaces (so the docs);
 - `--moved_suffix` (optional) is the suffix to add to the moved workspaces;

Example of use:
```
./gen-sql-move-docs-and-delete-account.bash --src=deleted-account@example.com --dst=dst@example.com --move_suffix="__from_deleted_account"
```

The result is a SQL query you have to execute directly in the database, with a transaction so if a step fails, all the changes are automatically rolled back.
