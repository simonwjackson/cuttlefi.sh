sync() {
  local -n args=$1

  mkdir -p "${args['--root-dir']}"
  mkdir -p "${args['--logs-dir']}"

  select_details='.subscriptions.feeds // [] | to_entries | map({name: .key} + .value) | .[] | "\(.name)\n\(.url)"'

  config_or_empty |
    yq \
      --raw-output \
      -c \
      "${select_details}" |
    while
      read -r name
      read -r url
    do
      [[ "${args['--log-level']}" != "error" ]] && echo "Downloading episodes for $name"
      download "args" "$name" "$url"
    done

  [[ "${args['--log-level']}" == "info" ]] && echo "All episodes downloaded to ${args['--root-dir']}"
}

download() {
  local -n g_args=$1
  local podcast_name=$2
  local rss_feed_url=$3
  local save_dir="${g_args['--root-dir']}/${podcast_name}"

  mkdir -p "$save_dir"

  local log_file="${g_args['--logs-dir']}/${podcast_name}.log"

  # TODO: limit downloaded items from yaml
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
        [[ "${g_args['--log-level']}" == "info" ]] && echo "Already downloaded: $filename"
        continue
      fi

      [[ "${g_args['--log-level']}" != "error" ]] && echo "Downloading episode: $url"
      wget -O "${save_dir}/${filename}" "$url" &&
        echo "$unique_id" >>"$log_file"
    done
}
