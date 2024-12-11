#!/usr/bin/env bash

#
# Prints all the data from the past name array on the screen.
#
# Each value will be on one line.
#
# @param array $1
# Array Name.
#
# @param ?bool $2
# ::
#   - default : "1"
# ::
#
# If the string is multiline and "1" is entered then it will be shown on a
# single line with the characters \n, \r and \t visible.
#
# @param ?int $3
# ::
#   - default : "0"
# ::
#
# Value max length.
# if zero or if omitted then there will be no limit.
#
# @return string
shellNS_array_dump() {
  local -n arrDump="${1}"
  local intLength="${#arrDump[@]}"

  local boolNormalize="0"
  if [ "${2}" == "1" ]; then boolNormalize="${2}"; fi

  local intMaxLength="0"
  if [ "${3}" != "" ] && [ "${3}" -gt "0" ]; then intMaxLength="${3}"; fi

  echo "Array Name    : ${1}"
  echo "Array Length  : ${intLength}"
  if [ "${#arrDump[@]}" -gt "0" ]; then
    local nn=$'\n'
    local rr=$'\r'
    local tt=$'\t'

    local k=""
    local v=""
    local -a arrDumpSortedKeys=($(for k in "${!arrDump[@]}"; do echo "${k}"; done | sort))

    for k in "${arrDumpSortedKeys[@]}"; do
      v="${arrDump["${k}"]}"
      if [ "${intMaxLength}" -gt "0" ]; then
        v="${v:0:${intMaxLength}}"
      fi

      if [ "${boolNormalize}" == "1" ]; then
        v="${v//$nn/\\\\n}"
        v="${v//$rr/\\\\r}"
        v="${v//$tt/\\\\t}"
      fi

      echo -e "  [\"${k}\"] => ${v}"
    done
  fi

  return 0
}
