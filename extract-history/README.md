# Extract history from Grist document

**Status: ✅ Ready to be used in production**

This tool allows you to extract the action history from a Grist document
and dump it as a series of JSON objects.

## Prerequisites

You need to have installed:

- sqlite3
- python3
- xxd

Optionally, you may want to use `jq` to extract information from the resulted JSON.

## Usage

In order to extract the history:

```bash
./extract-history.sh /path/to/file.grist 
```

You may also save the result in a file:

```bash
./extract-history.sh /path/to/file.grist > /tmp/history.txt
```

Or filter the information you want:

```bash
./extract-history.sh /path/to/file.grist | jq -r '.actionHash'
```
