#!/usr/bin/env bash

#
# Selects all the files that are part of the package and fills the indicated
# array with the full path with each one.
#
# @param array $1
# Name of the array that will be populated with the files that are part of
# the package.
#
# @return array
shellNS_main_select_package_files() {
  #
  # Files to assemble
  local -n arrTargetFiles="${1}"

  #
  # Package main directory
  local dirThisMainPackage="$(tmpPath=$(dirname "${BASH_SOURCE[0]}"); realpath "${tmpPath}")"

  #
  # Checks for dependencies on specific functions
  local tmpIterator=""
  if [ -d "${dirThisMainPackage}/_" ]; then
    for tmpIterator in $(find "${dirThisMainPackage}/_" -type f -name "*.sh"); do
      arrTargetFiles+=("${tmpIterator}")
    done
  fi

  #
  # Check for 'config.sh' file
  if [ -f "${dirThisMainPackage}/config.sh" ]; then
    arrTargetFiles+=("${dirThisMainPackage}/config.sh")
  fi

  #
  # Get 'config.sh' files
  if [ -d "${dirThisMainPackage}/src" ]; then
    for tmpIterator in $(find "${dirThisMainPackage}/src" -type f -name "config.sh"); do
      arrTargetFiles+=("${tmpIterator}")
    done

    #
    # Grab the rest of the files.
    for tmpIterator in $(find "${dirThisMainPackage}/src" -type f -name "*.sh" ! -name "config.sh" ! -name "*_test.sh"); do
      arrTargetFiles+=("${tmpIterator}")
    done
  fi

  #
  # Load the locale labels and adjusts
  local strFullPathToLocaleFile="${dirThisMainPackage}/locale/${SHELLNS_CONFIG_INTERFACE_LOCALE}.sh"
  if [ -f "${strFullPathToLocaleFile}" ]; then
    arrTargetFiles+=("${strFullPathToLocaleFile}")
  fi
}

#
# Exports a 'standalone.sh' file containing all the package code.
#
# @param array $1
# Name of the array that contains the files that must be added to the
# standalone package.
#
# @return void
shellNS_main_export_standalone() {
  local -n arrayExportFiles="${1}"

  local codeNL=$'\n'
  local strFileContent=""
  local strFileStandalone="#!/usr/bin/env bash${codeNL}${codeNL}"

  local strRawLine=""
  local strCleanLine=""


  local pathToTargetFile=""
  for pathToTargetFile in "${arrayExportFiles[@]}"; do
    strFileContent=$(< "${pathToTargetFile}")

    IFS=$'\n'
    while read -r strRawLine || [ -n "${strRawLine}" ]; do
      strCleanLine="${strRawLine}"
      strCleanLine="${strCleanLine#"${strCleanLine%%[![:space:]]*}"}" # trim L
      strCleanLine="${strCleanLine%"${strCleanLine##*[![:space:]]}"}" # trim R
      if [ "${strCleanLine}" != "" ] && [ "${strCleanLine:0:1}" != "#" ]; then
        strFileStandalone+="${strRawLine}${codeNL}"
      fi
    done <<< "${strFileContent}"
  done

  echo "${strFileStandalone}" > "standalone.sh"
}

#
# Starts this package in the context of the shell.
#
# @param string $1
# Type of execution to be done.
# Choose one of : load, export, utests
#
# @return void
shellNS_main_entrypoint() {
  local -a arrayPackageFiles=()
  shellNS_main_select_package_files "arrayPackageFiles"


  case "${1}" in
    "export")
      shellNS_main_export_standalone "arrayPackageFiles"
    ;;
    *)
      local pathToTargetFile=""
      for pathToTargetFile in "${arrayPackageFiles[@]}"; do
        . "${pathToTargetFile}"
      done
    ;;
  esac
}


shellNS_main_entrypoint "${1}"
unset shellNS_main_select_package_files
unset shellNS_main_export_standalone
unset shellNS_main_entrypoint