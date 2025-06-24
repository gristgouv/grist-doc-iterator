#!/usr/bin/env bash

set -eEu -o pipefail

# Usage: [MINIO_MC=<minio-mc>] [SQLITE3=<sqlite3>] ./doc-iterator/doc-iterator.sh [-w|--write] s3_path scripts...
help=false
write=false
verbose=false
scripts=()
if [[ $# -eq 0 ]]; then
  help=true
fi

debug() {
  if $verbose; then
    echo "DEBUG: " "$@"
  fi
}

info() {
  echo "INFO: " "$@"
}

error() {
  echo -e "\033[31mERROR:" "$@" "\033[0m" >&2
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      help=true
      shift
      ;;
    -w|--write)
      write=true
      shift
      ;;
    -v|--verbose)
      verbose=true
      shift
      ;;
    --only=*)
      only="${1#*=}"
      shift
      ;;
    -o)
      only="${2}"
      shift 2
      ;;
    --only-from-file=*)
      only_from_file="${1#*=}"
      shift
      ;;
    -O)
      only_from_file="${2}"
      shift 2
      ;;
    --exclude=*)
      exclude="${1#*=}"
      shift
      ;;
    -x)
      exclude="${2}"
      shift 2
      ;;
    --exclude-from-file=*)
      exclude_from_file="${1#*=}"
      shift
      ;;
    -X)
      exclude_from_file="${2}"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      help=true
      shift
      ;;
    *)
      if [ -z "${s3_path:-}" ]; then
        s3_path="${1/%\//}" # Remove trailing slash if present
      else
        scripts+=("$1")
      fi
      shift
      ;;
  esac
done

if $help; then
  echo "Usage: ./doc-iterator/doc-iterator.sh [OPTIONS] s3_path scripts..."
  echo "Options:"
  echo "  -h, --help                              Show this help message and exit"
  echo "  -o, --only                              Include only documents matching the given pattern (must be compatible with grep)"
  echo "  -O, --only-from-file=/path/to/file      Include only documents matching the given pattern (must be compatible with grep)"
  echo "  -w, --write                             Push back changes to S3 if the document has changed"
  echo "  -x, --exclude=PATTERN                   Exclude documents matching the given pattern (must be compatible with grep)"
  echo "  -X, --exclude-from-file=/path/to/file   Exclude documents matching the patterns specified in the given file (must be compatible with grep)"
  echo "  -v, --verbose                           Enable verbose output"
  echo "  s3_path                                 The S3 path to the docs"
  echo "  scripts                                 The scripts to run on the downloaded files"
  echo ""
  echo "Environment Variables:"
  echo "  MINIO_MC       The MinIO client command (default: mc)"
  echo "  SQLITE3        The SQLite3 command, exposed to each script (default: sqlite3)"
  exit 0
fi

# Check if s3_path is set
if [[ -z "${s3_path:-}" ]]; then
  error "s3_path is required."
  exit 1
fi

# Check if scripts are set
if [ "${#scripts[@]}" -eq 0 ]; then
  error "No scripts provided."
  exit 1
fi

# Check if MINIO_MC is set, if not, set it to the default value
MINIO_MC=${MINIO_MC:-"mc"}

minio_retry() {
  fibo=(0 1 2 3 5 8 13 21 34 55)
  for i in "${fibo[@]}"; do
    sleep "$i"
    if $MINIO_MC "$@"; then
      return 0
    fi
    debug "Problem occurred while running $MINIO_MC $*. Retry according to the fibonacci sequence"
  done
  error "Failed to run command $MINIO_MC $*"
  return 1
}

for script in "${scripts[@]}"; do
  # Check if the script exists and is executable
  if [[ ! -x "$script" ]]; then
    error "Script $script does not exist or is not executable."
    exit 1
  fi
done

# Check if we can list the S3 path

# List all .grist files in the S3 path, except those that contain a ~
files=$(minio_retry ls --json "$s3_path" | jq -r '.key | select(test("^[^~]+\\.grist$"))')

# Apply the filters
if [ -n "${only_from_file:-}" ]; then
  files=$(echo "$files" | grep -f "$only_from_file")
fi
if [ -n "${only:-}" ]; then
  files=$(echo "$files" | grep "$only")
fi
if [ -n "${exclude_from_file:-}" ]; then
  files=$(echo "$files" | grep -v -f "$exclude_from_file")
fi
if [ -n "${exclude:-}" ]; then
  files=$(echo "$files" | grep -v "$exclude")
fi

dest_tmp_dir=$(mktemp -d)

cleanup() {
  find "$dest_tmp_dir" -type f \( -name "*.grist" -o -name "*.sha256" \) -exec shred -z {} \;
  rm -rf "$dest_tmp_dir"
}

trap "cleanup" EXIT

for file in $files; do
  # Download the file to a temporary location
  remote_path="$s3_path/$file"
  tmp_file="$dest_tmp_dir/$file"
  tmp_file_sha256="${tmp_file}.sha256"
  if ! minio_retry get "$remote_path" "$tmp_file" &>/dev/null; then
    error "File does not exist, skip: $remote_path"
    continue
  fi
  sha256sum "$tmp_file" > "$tmp_file_sha256"

  # Run each script on the downloaded file
  for script in "${scripts[@]}"; do
    debug "Running script $script on file $tmp_file"
    SQLITE3=${SQLITE3:-"sqlite3"} $script "$tmp_file" && \
      info "✅ [SUCCESS] Successfully run script $script on $file" || \
      error "❌ [USER_ERROR] User script error for $script on $file"
  done

  # If write is true and changes has been made, push the new file to S3
  if $write; then
    if ! sha256sum -c "$tmp_file_sha256" &>/dev/null; then
      info "⬆️ Changes detected in $tmp_file, pushing to S3"
      minio_retry put "$tmp_file" "$remote_path" &>/dev/null
    else
      debug "No changes detected in $tmp_file, not pushing to S3"
    fi
  fi

  # Remove the temporary file
  shred -zu "$tmp_file" "$tmp_file_sha256"
done
