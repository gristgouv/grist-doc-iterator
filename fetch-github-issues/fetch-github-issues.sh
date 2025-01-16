#!/usr/bin/env bash

set -eEuo pipefail

PROJECT_ID=1
OWNER_NAME=gristlabs

fetch_column() {
  gh project item-list $PROJECT_ID --owner $OWNER_NAME --format json -L "$item_count" -q ".items[] | select(.status == \"$1\")" | jq -c
}

fetch_prs_with_label() {
  gh pr list --label "$1" --limit 100 --json number,url --format json | jq -c
}

format_project_item() {
  local title
  local item=$1
  local issue_url
  local pr_urls
  local pr_urls_formatted=''

  title=$(echo "$item" | jq -r '.title')
  issue_url=$(echo "$item" | jq -r '.content.url')
  pr_urls=$(echo "$item" | jq -rc '.["linked pull requests"]')

  if [ "$pr_urls" != 'null' ]; then
    pr_urls_formatted=$(echo "$pr_urls" | jq -r '. | map("[#" + split("/")[-1] + "](" + . + ")") | join (", ")')
  fi
  echo -n " - [$title]($issue_url)"
  if [ -n "$pr_urls_formatted" ]; then
    echo -n " (PRs: $pr_urls_formatted)"
  fi
  echo ""
}

show_done=''
show_needs_feedback=''
show_in_progress=''
archive_items=''
show_community=''

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -D|--done)
      show_done='true'
      shift
      ;;
    -N|--needs-feedback)
      show_needs_feedback='true'
      shift
      ;;
    -I|--in-progress)
      show_in_progress='true'
      shift
      ;;
    -A|--archive-done)
      archive_items='true'
      shift;;
    -C|--community)
      show_community='true'
      shift
      ;;
    -h|--help)
      echo "This script fetches the issues from a Github project and formats them in markdown."
      echo "Usage: $0 [-D|--done] [-N|--needs-feedback] [-I|--in-progress] [-A|--archive-done] [-c|--community] [-h|--help]"
      echo "  -D,--done: Show items in the Done column"
      echo "  -N,--needs-feedback: Show items in the Needs feedback column"
      echo "  -I,--in-progress: Show items in the In progress column"
      echo "  -A,--archive-done: Archive items in the Done column (default: false)"
      echo "  -C,--community: Show items in the Community column"
      echo "  -h,--help: Show this help message"
      echo "If no options are provided, all columns are shown"
      echo ""
      echo "In order to convert the output to html and copy it to the clipboard, run (using X on Linux):"
      echo "$0 | pandoc -f markdown -t html | xclip -selection clipboard -t text/html"
      echo "Or when using Wayland:"
      echo "$0 | pandoc -f markdown -t html | wl-copy -t text/html"

      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$archive_items" ] && [ -z "$show_done" ] && [ -z "$show_needs_feedback" ] && [ -z "$show_in_progress" ]; then
  show_done='true'
  show_needs_feedback='true'
  show_in_progress='true'
  show_community='true'
fi

if [ -n "$archive_items" ] && { 
  [ -n "$show_done" ] || [ -n "$show_needs_feedback" ] || [ -n "$show_in_progress" ] || [ -n "$show_community" ]
} ; then
  echo "Error: --archive-done cannot be used with other options"
  exit 1
fi

gh=$(which gh)

if [ -z "$gh" ]; then
  echo "Github CLI is not installed. Please install it from https://cli.github.com/"
  exit 1
fi

if ! gh project --help > /dev/null ; then
  echo "Error fetching project info from Github. gh is recent enough and includes gh project? You may need to update it or use the brew version."
  exit 1
fi

item_count=$(gh project view $PROJECT_ID --owner $OWNER_NAME -q '.items.totalCount' --format json)
if [ "$item_count" -eq 0 ]; then
  echo "No issues found in the project"
  exit 0
fi

cat <<EOF
Hello there! 👋

Below an update of our work!



EOF

IFS=$'\n'

if [ "$show_done" = 'true' ] || [ "$archive_items" = 'true' ]; then
  done=$(fetch_column "Done")
  if [ -n "$done" ]; then
    if [ "$show_done" = 'true' ]; then
      echo "**Newly merged 🎉**"
      echo "thanks for your reviews! 🙏"
      echo ""
      for item in $done; do
        format_project_item "$item"
        echo ": ... 👥 For our users, it means: ..."
      done
      echo ""
      echo ""
    fi

    if [ "$archive_items" = 'true' ]; then
      for item in $done; do
        id=$(echo "$item" | jq -r '.id')
        echo "Archiving item $id..."
        gh project item-archive $PROJECT_ID --owner $OWNER_NAME --id "$id"
      done
    fi
  fi
fi

if [ "$show_needs_feedback" = 'true' ]; then
  needs_feedback=$(fetch_column "Needs feedback")
  if [ -n "$needs_feedback" ]; then
    echo "**Needs Review and/or feedback (ordered by priority) 🔎**"
    echo ""
    for item in $needs_feedback; do
      format_project_item "$item"
    done
    echo ""
    echo ""
  fi
fi

if [ "$show_in_progress" = 'true' ]; then
  in_progress=$(fetch_column "In Progress")
  if [ -n "$in_progress" ]; then
    echo "**In Progress 🚧**"
    echo ""
    for item in $in_progress; do
      format_project_item "$item"
    done
    echo ""
    echo ""
  fi
fi

if [ "$show_community" = 'true' ]; then
  # noop
  echo ""

  # TODO:implement a logic for the community work on which we would like to raise attention.
  #
  # community=$(fetch_column "Community")
  # if [ -n "$community" ]; then
  #   echo "**Community 🌍**"
  #   echo ""
  #   for item in $community; do
  #     format_project_item "$item"
  #   done
  #   echo ""
  #   echo ""
  # fi
fi

echo "Cheers!"
