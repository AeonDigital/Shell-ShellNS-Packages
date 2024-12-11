#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_autostartscript_remove" "packages autoStartScript remove"

#
# Remove the 'auto-start script' snippet from your '.bashrc'.
#
# @return string
shellNS_packages_autostartscript_remove() {
  local strRawLine=""
  local strOldFileContent=$(< "${HOME}/.bashrc")
  local strNewFileContent=""
  local boolInclude="1"
  local codeNL=$'\n'

  IFS=$'\n'
  while read -r strRawLine || [ -n "${strRawLine}" ]; do
    if [ "${strRawLine}" == "# SHELLNS INI" ]; then
      boolInclude="0"
    fi

    if [ "${boolInclude}" == "1" ]; then
      strNewFileContent+="${strRawLine}${codeNL}"
    fi

    if [ "${strRawLine}" == "# SHELLNS END" ]; then
      boolInclude="1"
    fi
  done <<< "${strOldFileContent}"

  echo "${strNewFileContent}" > "${HOME}/.bashrc"
  if [ "$?" != "0" ]; then
    shellNS_dialog_set "error" "Unable to remove auto-start script in your '.bashrc'."
    shellNS_dialog_show
    return 1
  fi

  shellNS_dialog_set "ok" "The auto-start script for ShellNS has been removed from '.bashrc'.\n"
  shellNS_dialog_show
  return 0
}