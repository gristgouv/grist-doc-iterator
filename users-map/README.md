# Users map


**Status: ✅ Ready to be used in production**

Given a CSV file containing a dump of all our users which contains the SIRET of their organisation, retrieve the location of users' org.

## Prerequisites

Dependencies:
 - curl (on Debian-based distributions: `apt install curl`)
 - csvtool (on Debian-based distributions: `apt install csvtool`)

## Usage

```bash
# This will download the list of geolocation of organizations automatically:
./build-users-map.sh /path/to/all-users.csv /tmp/destination.csv

# This will reuse the passed file of geolocation
STOCK_ETABLISSEMENT=/path/to/StockEtablissementActif_utf8_geo.csv.gz ./build-users-map.sh /path/to/all-users.csv /tmp/destination.csv
```

Where the destination will contain all the field of the passed input csv plus the latitude and the longitude.

Other available optional env variables:
- `CSVTOOL` to specify the path to the csvtool binary;
- `CURL` to specify the path to the curl binary;
- `CLEANUP` to cleanup the temporary files after the execution;

