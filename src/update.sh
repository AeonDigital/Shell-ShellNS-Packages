#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_update" "packages update"

#
# Update installed packages.
#
# @param string $1...
# Enter the name of the packages you want to update, or enter 'ShellNS' to
# update all currently installed packages.
#
# @return string
shellNS_packages_update() {
  local strPackageName=""
  local strPackageDirectory=""
  local -A assocTgtUpdatePackage
  local strMsg=""



  if [ "${1}" == "ShellNS" ]; then
    local strRawLine=""

    while IFS="" read -r strRawLine; do
      assocTgtUpdatePackage["${strRawLine}"]="${SHELLNS_CONFIG_PACKAGES_DIR}/${strRawLine}"
    done < <(shellNS_packages_list 1)
  else
    for strPackageName in "$@"; do
      strPackageDirectory="${SHELLNS_CONFIG_PACKAGES_DIR}/${strPackageName}"
      if [ -d "${strPackageDirectory}" ]; then
        assocTgtUpdatePackage["${strPackageName}"]="${strPackageDirectory}"
      fi
    done
  fi



  if [ "${#assocTgtUpdatePackage[@]}" == "0" ]; then
    strMsg+="No packages were identified with the criteria passed.\n"
    strMsg+="This action was aborted."

    shellNS_dialog_set "fail" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi



  local strPackageUpdateError=""
  local strPackageUpdateSuccess=""
  for strPackageName in "${!assocTgtUpdatePackage[@]}"; do
    strPackageDirectory="${assocTgtUpdatePackage[${strPackageName}]}"

    git -C "${strPackageDirectory}" pull --rebase
    if [ "$?" == "0" ]; then
      strPackageUpdateSuccess="- ${strPackageName}\n"
    else
      strPackageUpdateError="- ${strPackageName}\n"
    fi
  done



  strMsg+="Result of the update process:\n"
  if [ "${strPackageUpdateSuccess}" != "" ]; then
    ((intMessageType++))
    strMsg+="The following packages have been updated:\n"
    strMsg+="${strPackageUpdateSuccess}"
  fi
  if [ "${strPackageUpdateError}" != "" ]; then
    strMsg+="The following packages could not be updated:\n"
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