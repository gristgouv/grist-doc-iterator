# Doc iterator

**Status: ✅ Ready to be used in production**

⚠️: Despite our efforts to avoid bugs in this script, please check your
backups before running it, especially if you intend to use the `-w` option.

This script allows you to run scripts on each Grist document in your S3 bucket.

## Use case

It covers many use cases:
 - you want to extract information about each document (like the widgets being used);
 - you want to vacuum the documents to reduce their size;
 - ...

💡 Notes: You have published under the [`scripts/`](scripts/) subfolder some scripts that may be of interest.

## Usage

See `./doc-iterator.sh --help`.

## Configuring mc alias

For local use, an alias can be created for `mc` using `mc alias set <ALIAS> <URL> <ACCESSKEY> <SECRETKEY>`.

For container use, the alias can also be configure using an environment variable using this format: `MC_HOST_<alias>=https://<Access Key>:<Secret Key>@<YOUR-S3-ENDPOINT>`.

### Example of use

*vacuum.sh*
```bash
#!/usr/bin/env bash
set -eEuo pipefail

$SQLITE3 "$1" "vacuum"
```

*list-tables.sh*
```bash
#!/usr/bin/env bash
set -eEuo pipefail

doc_id=$(basename -s ".grist" "$1")
$SQLITE3 "$1" ".tables" > "/tmp/${doc_id}.txt"
```

*To run it now on staging environment (given `staging-grist` is an alias registered in your minio client configuration):*
```bash
$ chmod u+x  ./vacuum.sh ./list-tables.sh
$ bash ./doc-iterator.sh -w staging-grist/grist-preprod-grist/docs/ ./vacuum.sh ./list-tables.sh
```

