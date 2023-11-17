#!/usr/bin/env bash

appName=$(basename "${0}")

usage() {
  cat <<EOU
Usage:
  $appName [options] sync
  $appName [options] list

Options:
  -c --config FILE      Specify an alternate configuration file.
  -r --root-dir DIR     Set the root directory for saving podcast episodes.
  -l --logs-dir DIR     Set the directory for saving logs.
  -L --log-level LEVEL  Set the logging level (info, warn, error).
  -h --help          Show this screen.
EOU
}

eval "$(docopts -A ARGS -h "$(usage)" : "$@")"

config_or_empty() {
  [ -f "${config_file}" ] &&
    cat "${config_file}" ||
    echo '---'
}

# Subcommands
list=${ARGS[list]:-false}
sync=${ARGS[sync]:-false}

# Args
config_file="${ARGS[--config]:-${HOME}/.config/${appName}/config.yml}"
root_dir="${ARGS['--root-dir']:-$(config_or_empty | yq --raw-output '."root-dir" // "'"$(pwd)"'"')}"
logs_dir="${ARGS['--logs-dir']:-$(config_or_empty | yq --raw-output '."logs-dir" // "'"$(pwd)"'"')}"
log_level="${ARGS['--log-level']:-$(config_or_empty | yq --raw-output '."log-level" // "info"')}"

download_podcast_episodes() {
  local podcast_name=$1
  local rss_feed_url=$2
  local save_dir="${root_dir}/${podcast_name}"

  mkdir -p "$save_dir"

  local log_file="${logs_dir}/${podcast_name}.log"

  wget -qO- "$rss_feed_url" |
    xmlstarlet sel -t -m "//item" -v "guid" \
      -o "|" -v "pubDate" \
      -o "|" -v "title" \
      -o "|" -v "enclosure/@url" -n |
    while IFS='|' read -r guid date title url; do
      local unique_id="${guid:-$(echo -n "$url" | md5sum | awk '{print $1}')}"

      formatted_date=$(date -d "$date" +%Y-%m-%d)

      safe_title=$(echo "$title" | tr " " "_")

      ext="${url##*.}"

      filename="${formatted_date}-${safe_title}-${unique_id}.${ext}"

      if grep -q "$unique_id" "$log_file"; then
        [[ "$log_level" == "info" ]] && echo "Already downloaded: $filename"
        continue
      fi

      [[ "$log_level" != "error" ]] && echo "Downloading episode: $url"
      wget -O "${save_dir}/${filename}" "$url" &&
        echo "$unique_id" >>"$log_file"
    done
}

sync() {
  mkdir -p "$root_dir"
  mkdir -p "$logs_dir"

  select_details='.subscriptions // [] | to_entries | map({name: .key} + .value) | .[] | "\(.name)\n\(.url)"'

  config_or_empty |
    yq \
      --raw-output \
      -c \
      "${select_details}" |
    while
      read -r name
      read -r url
    do
      [[ "$log_level" != "error" ]] && echo "Downloading episodes for $name"
      download_podcast_episodes "$name" "$url"
    done

  [[ "$log_level" == "info" ]] && echo "All episodes downloaded to ${root_dir}"
}

list() {
  local files_found

  files_found=$(find "$root_dir" -type f)

  if [ -z "$files_found" ] && [ "$log_level" == "info" ]; then
    echo "No podcasts found"
    return
  fi

  echo "$files_found" | while read -r episode; do
    echo "$episode"
  done
}

if [ "$list" = true ]; then
  list
elif [ "$sync" = true ]; then
  sync
fi

for a in "${!ARGS[@]}"; do
  echo "$a = ${ARGS[$a]}"
done
