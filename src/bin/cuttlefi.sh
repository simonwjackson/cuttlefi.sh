#!/usr/bin/env bash

appName=$(basename "${0}")

usage() {
  cat <<EOU
Usage:
  $appName sync [options]
  $appName list [options]

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
root_dir="${ARGS[--root_dir]:-$(config_or_empty | yq --raw-output '.root_dir // "'"$(pwd)"'"')}"
logs_dir="${ARGS[--logs_dir]:-$(config_or_empty | yq --raw-output '.logs_dir // "'"$(pwd)"'"')}"
log_level="${ARGS[--log_level]:-$(config_or_empty | yq --raw-output '.log_level // "info"')}"

# Function to download episodes for a given podcast
download_podcast_episodes() {
  local podcast_name=$1
  local rss_feed_url=$2
  local save_dir="${root_dir}/${podcast_name}"

  # Create directory for the podcast if it doesn't exist
  mkdir -p "$save_dir"

  # Log file for the podcast
  local log_file="${logs_dir}/${podcast_name}.log"

  # Process each item in the RSS feed
  wget -qO- "$rss_feed_url" |
    xmlstarlet sel -t -m "//item" -v "guid" \
      -o "|" -v "pubDate" \
      -o "|" -v "title" \
      -o "|" -v "enclosure/@url" -n |
    while IFS='|' read -r guid date title url; do
      # Use GUID as unique identifier or hash the URL if GUID is missing
      local unique_id="${guid:-$(echo -n "$url" | md5sum | awk '{print $1}')}"

      # Format the date
      formatted_date=$(date -d "$date" +%Y-%m-%d)

      # Replace spaces with underscores in the title
      safe_title=$(echo "$title" | tr " " "_")

      # Extract the file extension from the URL
      ext="${url##*.}"

      # Construct the filename
      filename="${formatted_date}-${safe_title}-${unique_id}.${ext}"

      # Check if the episode has already been downloaded
      if grep -q "$unique_id" "$log_file"; then
        [[ "$log_level" == "info" ]] && echo "Already downloaded: $filename"
        continue
      fi

      # Download the episode
      [[ "$log_level" != "error" ]] && echo "Downloading episode: $url"
      wget -O "${save_dir}/${filename}" "$url"

      # Log the downloaded episode
      echo "$unique_id" >>"$log_file"
    done
}

# Function to synchronize podcasts
sync() {
  # Create the directory to save episodes if it doesn't exist
  mkdir -p "$root_dir"
  mkdir -p "$logs_dir"

  config_or_empty | yq -r -c '.subscriptions // [] | to_entries | map({name: .key} + .value) | .[] | "\(.name)\n\(.url)"' | while
    read -r name
    read -r url
  do
    [[ "$log_level" != "error" ]] && echo "Downloading episodes for $name"
    download_podcast_episodes "$name" "$url"
  done

  [[ "$log_level" == "info" ]] && echo "All episodes downloaded to $root_dir"
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

# for a in "${!ARGS[@]}"; do
#   echo "$a = ${ARGS[$a]}"
# done
