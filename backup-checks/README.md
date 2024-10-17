# Check backups are made on S3

Check our backups are made on our S3 storage.

## Prerequisites

Ensure that you have [minio-mc](https://min.io/docs/minio/linux/reference/minio-mc.html) installed and configured to consult the storages.

## Env variables to set 

You may set the following env variables so the script runs correctly:
| Env name | Default value | Comment |
| ------------- | -------------- | -------------- |
| MC_ALIAS | prod-grist | The name of the alias to access the S3 bucket |
| PROD_BUCKET | donnees-grist-production-snapshots | The name of the bucket to check the existance of backups |

## Run it 

You may run the script using this command:
```bash
MC_ALIAS='my-alias' PROD_BUCKET='donnees-grist-production-snapshots' ./check-backups.sh
```

Then you should see whether the checks succeed or fail.
