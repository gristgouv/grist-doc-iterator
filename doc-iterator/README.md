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

## Usage

See `./doc-iterator.sh --help`.

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

