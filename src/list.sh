#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_list" "packages list"

#
# Lists installed packages.
#
# @param bool $1
# ::
#   - default : "0"
#   - list    : SHELLNS_PROMPT_OPTION_BOOL
# ::
#
# If '1' shows only package names.
#
# @return string
shellNS_packages_list() {
  local strMessage=""
  local boolOnlyNames="${1:-0}"
  local strPkg=""

  local -a arrayCorePackages=("${!SHELLNS_CONFIG_CORE_PACKAGES[@]}")
  IFS=$'\n' arrayCorePackages=($(sort <<<"${arrayCorePackages[*]}"))
  unset IFS



  if [ "${boolOnlyNames}" == "0" ]; then
    echo "Core Packages:"
  fi
  for strPkg in "${arrayCorePackages[@]}"; do
    if [ "${boolOnlyNames}" == "1" ]; then
      echo "${strPkg}"
    else
      echo "  ${strPkg}"
    fi
  done


  if [ "${#SHELLNS_CONFIG_PACKAGES_LOADED[@]}" -gt "0" ]; then
    if [ "${boolOnlyNames}" == "0" ]; then
      echo "Non Core Packages:"
    fi
    for strPkg in "${SHELLNS_CONFIG_PACKAGES_LOADED[@]}"; do
      if [ "${boolOnlyNames}" == "1" ]; then
        echo "${strPkg}"
      else
        echo "  ${strPkg}"
      fi
    done
  fi
  return 0
}