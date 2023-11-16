#!/usr/bin/env bash

usage() {
  cat <<EOU
Usage:
  $(basename "${0}") sync [options]
  $(basename "${0}") list [options]

Options:
  --root-dir DIR     Set the root directory for saving podcast episodes.
  --logs-dir DIR     Set the directory for saving logs.
  --log-level LEVEL  Set the logging level (info, warn, error).
  -h --help          Show this screen.
EOU
}

eval "$(docopts -A ARGS -h "$(usage)" : "$@")"

# YAML configuration file containing podcast subscriptions
config_file="/tmp/podcast_config.yaml"

# Default values for configurations
default_root_dir="$(pwd)"
default_logs_dir="$(pwd)"
default_log_level="info"

# Read configurations from YAML file
root_dir="$(yq --raw-output '.root_dir // "'"$default_root_dir"'"' "${config_file}")"
logs_dir="$(yq --raw-output '.logs_dir // "'"$default_logs_dir"'"' "${config_file}")"
log_level="$(yq --raw-output '.log_level // "'$default_log_level'"' "${config_file}")"

root_dir=${ARGS[root_dir]:-$root_dir}
[[ -n "${logs_dir_arg}" ]] && logs_dir="${logs_dir_arg}"
[[ -n "${log_level_arg}" ]] && log_level="${log_level_arg}"

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

  # Read each subscription from the YAML file and download episodes
  yq -r -c '.subscriptions | to_entries | map({name: .key} + .value) | .[] | "\(.name)\n\(.url)"' "$config_file" | while
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

list=${ARGS[list]:-false}
sync=${ARGS[sync]:-false}

if [ "$list" = true ]; then
  list
elif [ "$sync" = true ]; then
  sync
fi

# for a in "${!ARGS[@]}"; do
#   echo "$a = ${ARGS[$a]}"
# done
