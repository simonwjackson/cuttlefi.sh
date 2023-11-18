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
  [ -f "${ARGS['--config']}" ] &&
    cat "${ARGS['--config']}" ||
    echo '---'
}

# Subcommands
list=${ARGS[list]:-false}
sync=${ARGS[sync]:-false}

# Args
ARGS['--config']="${ARGS['--config']:-${HOME}/.config/${appName}/config.yml}"
ARGS['--root-dir']="${ARGS['--root-dir']:-$(config_or_empty | yq --raw-output '."root-dir" // "'"$(pwd)"'"')}"
ARGS['--logs-dir']="${ARGS['--logs-dir']:-$(config_or_empty | yq --raw-output '."logs-dir" // "'"$(pwd)"'"')}"
ARGS['--log-level']="${ARGS['--log-level']:-$(config_or_empty | yq --raw-output '."log-level" // "info"')}"

source ./commands/list.sh
source ./commands/sync.sh

if [ "$list" = true ]; then
  list "ARGS"
elif [ "$sync" = true ]; then
  sync "ARGS"
fi

# for a in "${!ARGS[@]}"; do
#   echo "$a = ${ARGS[$a]}"
# done
