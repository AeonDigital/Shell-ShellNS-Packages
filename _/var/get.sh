#!/usr/bin/env bash

#
# Returns the default value to be used according to the rules defined in the
# arguments.
#
# @param string $1
# Current Value.
#
# @param string $2
# Value to be returned if current value is empty or invalid.
#
# @param ?string[ ] $3
# If defined, it should be a list of strings separated by spaces representing
# each of the valid values.
#
# @return string
shellNS_var_get() {
  local strCurrentValue="${1}"
  local strDefaultValueIfEmptyOrInvalid="${2}"

  IFS=$'\n'
  local tmpCode="local -a arrValidOptions=("${3}")"
  eval "${tmpCode}"
  IFS=$' \t\n'

  local strReturn="${strDefaultValueIfEmptyOrInvalid}"
  if [ "${#arrValidOptions[@]}" == "0" ] && [ "${strCurrentValue}" != "" ]; then
    strReturn="${strCurrentValue}"
  fi

  if [ "${#arrValidOptions[@]}" -gt "0" ]; then
    local value=""

    for value in "${arrValidOptions[@]}"; do
      if [ "${strCurrentValue}" == "${value}" ]; then
        strReturn="${strCurrentValue}"
        break
      fi
    done
  fi

  echo -ne "${strReturn}"
}
