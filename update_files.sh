#!/usr/bin/env bash
#######################################
# This script reproduces files in given directory(or single file)
# across hosts specified in file.
# Requires Bash 4+ due to mapfile.
# Use with SSH keys.
# Globals:
#   USER - user used to access remote host
#   HOSTS_FILE - file with remote hosts addresses/hostnames separated by new line
#   TIMESTAMP - current timestamp
# Arguments:
#   no args - copies files from current directory
#   directory arg - copies files from given directory
#   file arg - copies given file
#######################################
set -eu
declare -r USER=user
declare -r HOSTS_FILE=hosts.txt
# shellcheck disable=SC2155
declare -r TIMESTAMP=$(date +%d-%m-%Y_%H-%M-%S)

#######################################
# Copies file from host to remote directory.
# If file with given name already exists on remote host
# previous version is saved with current timestamp.
# Globals:
#   USER
#   TIMESTAMP
# Arguments:
#   Remote hostname/address, file, directory.
#######################################
function _update_remote_file() {
  local -r host="${1}"
  local -r file="${2}"
  local -r dir="${3}"
  set -x
  ssh "${USER}"@"${host}" [[ -f "${file}" ]] &&
    ssh "${USER}"@"${host}" mv "${file}" "${file}"."${TIMESTAMP}" &&
    scp "${file}" "${USER}"@"${host}":"${dir}" ||
    scp "${file}" "${USER}"@"${host}":"${dir}"
  set +x
}

function main() {
  mapfile -t hosts <"${HOSTS_FILE}"
  if [ $# -eq 0 ] || [ -d "$1" ]; then
    local -r dir=$(if [ $# -eq 0 ]; then echo "$PWD"; else echo "$1"; fi)
    for file in "${dir}"/*; do
      if [[ -f ${file} ]] && true; then
        for host in "${hosts[@]}"; do
          _update_remote_file "${host}" "${file}" "$(dirname "$file")"
        done
      fi
    done
  elif [ -f "$1" ]; then
    for host in "${hosts[@]}"; do
      _update_remote_file "${host}" "$1" "$(dirname "$1")"
    done
  fi
}

main "$@"
