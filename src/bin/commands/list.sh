list() {
  local -n args=$1
  local files_found

  files_found=$(find "${args['--root-dir']}" -type f)

  if [ -z "$files_found" ] && [ "${args['--log-level']}" == "info" ]; then
    echo "No podcasts found"
    return
  fi

  echo "$files_found" | while read -r episode; do
    echo "${episode}"
  done
}
