#!/bin/bash

set -eEu -o pipefail

CSVTOOL=${CSVTOOL:-csvtool}
CURL=${CURL:-curl}
all_users_csv="${1:-}"
destination="${2:-}"

SED_NORMALIZE_REPLACE='s/[[:space:]]//g'

error() {
  echo "$@" >&2
}

info() {
  echo "$@"
}

col_pos() {
  csv=$1
  col=$2
  head -n 1 "$csv" | awk -F',' "{for(i=1;i<=NF;i++) if(\$i==\"$col\") print i}"
}

if ! command -v "$CSVTOOL" >/dev/null; then
  error "Please install csvtool (\`apt install csvtool\` on debian-based linux distro) or provide it through the CSVTOOL env var"
  exit 1
fi

if ! command -v "$CURL" >/dev/null; then
  error "Please install curl (\`apt install curl\` on debian-based linux distro) or provide it through the CURL env var"
  exit 1
fi

if [ ! -r "$all_users_csv" ]; then
  error "CSV file not readable or not provided"
  exit 1
fi

if [ "$#" -lt 2 ]; then
  error "Usage: $0 /path/to/all-users.csv /path/to/destination.csv"
  exit 1
fi

if [ -f "$destination" ]; then
  error "Destination exists, I won't overwrite it: $destination"
  exit 1
fi

search_patterns=$(mktemp --suffix="siretloc.search.txt")
$CSVTOOL namedcol siret "$all_users_csv" | \
  # keep only unique values for SIRETs
  sort -u | \
  # Discard any unrelevant values (and the header)
  grep "^[0-9]" | \
  # Normalize the value, remove the spaces
  sed "$SED_NORMALIZE_REPLACE" | \
  # Split the Siret into a tuple of siren and nic, and prefix the pattern with `^` to search only at the beginning of the line
  sed 's/^\(.\{9\}\)\(.*\)/^\1,\2/g' > "$search_patterns"

stock_etablissement=${STOCK_ETABLISSEMENT:-""}
if [ "$stock_etablissement" == "" ]; then
  stock_etablissement_dir=$(mktemp --directory --suffix="stock_etablissement")
  mkdir -p "$stock_etablissement_dir"
  stock_etablissement="${stock_etablissement_dir}/StockEtablissementActif_utf8_geo.csv.gz"
  info "Downloading $stock_etablissement, may take a while"
  $CURL "https://files.data.gouv.fr/geo-sirene/last/StockEtablissementActif_utf8_geo.csv.gz" > "$stock_etablissement"
fi

cat="cat"
if [ "$(file -b --mime-type "$stock_etablissement")" == "application/gzip" ]; then
  cat="zcat"
fi

grepped_etablissements_with_loc=$(mktemp --suffix="grepped_etablissements.csv")

info "Searching for \"Etablissements\" (may take a while)"
cat << EOF | $CSVTOOL namedcol "siret,longitude,latitude" - > "$grepped_etablissements_with_loc"
$($cat "$stock_etablissement" | head -n 1)
$($cat "$stock_etablissement" | grep --file="$search_patterns")
EOF


# csvtool join does not seem to work as we would like and seems very complex, let's yolo iterate on the document and grep

siret_col_pos=$(col_pos "$all_users_csv" "siret")
email_col_pos=$(col_pos "$all_users_csv" "email")

# Print the header
info "Generating destination"
echo "$(head -n 1 "$all_users_csv"),longitude,latitude" > "$destination"
MISSING_SIRET_VALUE="MISSING_SIRET_VALUE"
declare -A unique_emails

while read -r line; do
  # extract the SIRET from the line, it is at the position $siret_col_pos
  siret=$(echo "$line" | csvtool col "$siret_col_pos" - | sed "$SED_NORMALIZE_REPLACE")

  if [ "${DEDUP:-0}" == "1" ]; then
    email=$(echo "$line" | csvtool col "$email_col_pos" - | tr '[:upper:]' '[:lower:]')
    if [ -n "$siret" ] && [ -n "$email" ] && [ "${unique_emails["$email"]:-}" == "$MISSING_SIRET_VALUE" ]; then
      # Note: in destination, email are already normalized
      # grep: -F to treat pattern as plain text and not as regex, -x to only match the whole line, and -n to prepend with line number
      linenum_to_del="$(csvtool namedcol "email" "$destination" | grep -Fxn "$email" | cut -d ":" -f1)"

      # Delete the line with the same email in the destination file
      [ -n "$linenum_to_del" ] && sed -i "${linenum_to_del}d" "$destination"

    elif [ -z "$email" ] || [ -n "${unique_emails["$email"]:-}" ]; then # If the email has already been processed, skip
      continue
    fi
    unique_emails["$email"]="${siret:-$MISSING_SIRET_VALUE}"
  fi

  if [ -z "$siret" ]; then
    echo "$line,," >> "$destination"
    continue
  fi
  # search for the SIRET in the grepped_etablissements_with_loc file and retrieve the location values only
  loc=$(sed -n "s/^$siret,//p" "$grepped_etablissements_with_loc" || true)
  if [ -n "$loc" ]; then
    # if found, append the line to the destination file
    echo "$line,$loc" >> "$destination"
  else
    # if not found, append the line with empty longitude and latitude
    echo "$line,," >> "$destination"
  fi
done < <(tail -n +2 "$all_users_csv") # `tail -n +2` ignores the first line

if [ "${CLEANUP:-0}" == "1" ]; then
  rm "$search_patterns"
  rm "$grepped_etablissements_with_loc"
  if [ -n "${stock_etablissement_dir:-}" ] && [ -d "${stock_etablissement_dir}" ]; then
    rm -rf "$stock_etablissement_dir"
  fi
fi

