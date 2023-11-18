#!/usr/bin/env bash

appName=$(basename "${0}")

usage() {
  cat <<EOU
Usage:
  $appName [options] sync
  $appName [options] list
  $appName help

Options:
  -c --config FILE        Specify an alternate configuration file.
  -r --root-dir DIR       Set the root directory for saving podcast episodes.
  -l --logs-dir DIR       Set the directory for saving logs.
  -L --log-level LEVEL    Set the logging level (info, warn, error).
  -h --help               Show this screen.
EOU
}

eval "$(docopts -A ARGS -h "$(usage)" : "$@")"

config_or_empty() {
  [ -f "${ARGS['--config']}" ] &&
    cat "${ARGS['--config']}" ||
    echo '---'
}

# Args
ARGS['--config']="${ARGS['--config']:-${HOME}/.config/${appName}/config.yml}"
ARGS['--root-dir']="${ARGS['--root-dir']:-$(config_or_empty | yq --raw-output '."root-dir" // ""')}"
if [ -z "${ARGS['--root-dir']}" ]; then
  printf "\n"
  echo -e "Error: Specify the root directory using '--root-dir' argument or set the 'root-dir' key in your config file.\n"

  $(basename "${0}") --help

  exit 1
fi
ARGS['--logs-dir']="${ARGS['--logs-dir']:-$(config_or_empty | yq --raw-output '."logs-dir" // "'"${ARGS['--root-dir']}"'"')}"
ARGS['--log-level']="${ARGS['--log-level']:-$(config_or_empty | yq --raw-output '."log-level" // "info"')}"

# Subcommands
# TODO: add cleanup command
source commands/list.sh
source commands/sync.sh

if [ "${ARGS[help]}" = true ]; then
  $(basename "${0}") help
elif [ "${ARGS[list]}" = true ]; then
  list "ARGS"
elif [ "${ARGS[sync]}" = true ]; then
  sync "ARGS"
fi

for a in "${!ARGS[@]}"; do
  echo "$a = ${ARGS[$a]}"
done
