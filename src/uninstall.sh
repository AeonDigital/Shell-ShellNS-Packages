#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_uninstall" "packages uninstall"

#
# Uninstall installed packages.
# Core packages cannot be uninstalled without removing all of ShellNS.
#
# @param string $1...
# Enter the name of the packages you want to uninstall, or enter 'ShellNS' to
# remove the project from your computer entirely.
#
# @return string
shellNS_packages_uninstall() {
  local strPackageName=""
  local strPackageDirectory=""
  local -A assocTgtUpdatePackage
  local strListToRemove=""
  local strMsg=""



  if [ "${1}" == "ShellNS" ]; then
    local strRawLine=""

    while IFS="" read -r strRawLine; do
      assocTgtUpdatePackage["${strRawLine}"]="${SHELLNS_CONFIG_PACKAGES_DIR}/${strRawLine}"
      strListToRemove+="- ${strRawLine}\n"
    done < <(shellNS_packages_list 1)
  else
    local hasCore="0"
    for strPackageName in "$@"; do
      strPackageDirectory="${SHELLNS_CONFIG_PACKAGES_DIR}/${strPackageName}"
      if [ -d "${strPackageDirectory}" ]; then
        assocTgtUpdatePackage["${strPackageName}"]="${strPackageDirectory}"
        strListToRemove+="- ${strPackageName}\n"

        if [ "${SHELLNS_CONFIG_CORE_PACKAGES[${strPackageName}]}" != "" ]; then
          hasCore="1"
        fi
      fi
    done


    if [ "${hasCore}" == "1" ]; then
      strMsg+="Core packages cannot be removed.\n"
      strMsg+="This action was aborted."

      shellNS_dialog_set "fail" "${strMsg}"
      shellNS_dialog_show
      return 1
    fi
  fi



  if [ "${#assocTgtUpdatePackage[@]}" == "0" ]; then
    strMsg+="No packages were identified with the criteria passed.\n"
    strMsg+="This action was aborted."

    shellNS_dialog_set "fail" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi



  strMsg+="This action cannot be undone!\n"
  strMsg+="Confirm complete removal of the packages listed below:\n"
  strMsg+="${strListToRemove}\n\n"

  shellNS_prompt_set "question" "${strMsg}" "1" "0" "1" "SHELLNS_PROMPT_OPTION_BOOL"
  shellNS_prompt_show

  local p=$(shellNS_prompt_get)
  if [ "${p}" != "1" ]; then
    strMsg=""
    strMsg+="Uninstall aborted."

    shellNS_dialog_set "info" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi
  strMsg=""



  if [ "${1}" == "ShellNS" ]; then
    rm -rf "${SHELLNS_CONFIG_MAIN_DIR}"
    if [ "$?" != "0" ]; then
      strMsg+="Unable to remove 'ShellNS' project from install location:\n"
      strMsg+="- '${SHELLNS_CONFIG_MAIN_DIR}'"
      strMsg+="Make sure the permissions allow you to delete this directory and try again."

      shellNS_dialog_set "error" "${strMsg}"
      shellNS_dialog_show
      return 1
    fi

    strMsg+="ShellNS has been completely removed from your computer\n"

    shellNS_dialog_set "ok" "${strMsg}"
    shellNS_dialog_show

    shellNS_packages_autostartscript_remove
    return 0
  fi



  local strPackageUpdateError=""
  local strPackageUpdateSuccess=""
  for strPackageName in "${!assocTgtUpdatePackage[@]}"; do
    strPackageDirectory="${assocTgtUpdatePackage[${strPackageName}]}"

    rm -rf "${strPackageDirectory}"
    if [ "$?" == "0" ]; then
      strPackageUpdateSuccess="- ${strPackageName}\n"
    else
      strPackageUpdateError="- ${strPackageName}\n"
    fi
  done



  strMsg+="Result of the uninstall process:\n"
  if [ "${strPackageUpdateSuccess}" != "" ]; then
    ((intMessageType++))
    strMsg+="The following packages have been removed:\n"
    strMsg+="${strPackageUpdateSuccess}"
  fi
  if [ "${strPackageUpdateError}" != "" ]; then
    strMsg+="The following packages could not be removed:\n"
    strMsg+="${strPackageUpdateError}"
  fi

  local strMessageType=""
  if [ "${strPackageUpdateSuccess}" != "" ] && [ "${strPackageUpdateError}" == "" ]; then
    strMessageType="ok"
  fi
  if [ "${strPackageUpdateSuccess}" != "" ] && [ "${strPackageUpdateError}" != "" ]; then
    strMessageType="info"
  fi
  if [ "${strPackageUpdateSuccess}" == "" ] && [ "${strPackageUpdateError}" != "" ]; then
    strMessageType="fail"
  fi

  if [ "${strMessageType}" != "fail" ]; then
    strMsg+="\n"
    strMsg+="The results of this action will be effective from the next session."
  fi

  shellNS_dialog_set "${strMessageType}" "${strMsg}"
  shellNS_dialog_show
  return 0
}