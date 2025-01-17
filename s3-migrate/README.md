# s3-migrate

**Status: 🧪 Experimental**

**Important**: ⚠️ There is not much documentation, also it has been run for our own purpose. **Really** take a close look at the code and use it at your own risk. You would probably need to adapt it for your own usage. **No assistance of any sort will be provided.** ⚠️

## Description

The script `s3-copy.py` helps migrate your Grist documents from a S3 bucket to another one.

In our case, the source bucket was hosted on Scaleway, and we migrated to a MinIO server.

Also `clean-history.sh` exists to prune the history size to 10 entries, in order to shrink the disk usage on the destination bucket. We could save between 50% to 75% of it.
