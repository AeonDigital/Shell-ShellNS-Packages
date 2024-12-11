#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_autostartscript_insert" "packages autoStartScript insert"

#
# Inserts the 'auto-start script' snippet into your '.bashrc'.
#
# @param string $1
# Locale a ser usado.
# Se não for definido usará o padrão 'en-us'.
#
# @return string
shellNS_packages_autostartscript_insert() {
  local strLocale="${1,,}"
  if [ "${strLocale}" == "" ]; then
    strLocale="en-us"
  fi

  local strLauncher=""
  strLauncher+="# SHELLNS INI\n"
  strLauncher+="SHELLNS_CONFIG_INTERFACE_LOCALE=\"${strLocale}\"\n"
  strLauncher+=". \"${SHELLNS_CONFIG_MAIN_DIR}/start.sh\"\n"
  strLauncher+="# SHELLNS END\n"

  shellNS_packages_disable
  echo -ne "${strLauncher}" >> "${HOME}/.bashrc"
  if [ "$?" != "0" ]; then
    shellNS_dialog_set "error" "Unable to add auto-start script in your '.bashrc'."
    shellNS_dialog_show
    return 1
  fi

  local strOk=""
  strOk+="The auto-start script for ShellNS has been added to '.bashrc'.\n"
  strOk+="Using locale '${strLocale}'"
  shellNS_dialog_set "ok" "${strOk}"
  shellNS_dialog_show
  return 0
}