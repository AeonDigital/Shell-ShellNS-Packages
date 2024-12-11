#!/usr/bin/env bash

shellNS_register "${BASH_SOURCE[0]}" "shellNS_packages_install" "packages install"

#
# Install new packages.
#
# @param urlFullPath $1
# URL of the git repository of the package that will be installed.
#
# @return string
shellNS_packages_install() {
  local strURLPackage="${1}"
  strURLPackage="${strURLPackage#"${strURLPackage%%[![:space:]]*}"}" # trim L
  strURLPackage="${strURLPackage%"${strURLPackage##*[![:space:]]}"}" # trim R

  local strMsg=""
  if [ "${strURLPackage}" == "" ]; then
      strMsg+="You need to provide the URL of the GIT repository of the package to be installed.\n"

      shellNS_dialog_set "fail" "${strMsg}"
      shellNS_dialog_show
  fi



  local strPackageName=$(basename "${strURLPackage}")
  local strPackageDirectory="${SHELLNS_CONFIG_PACKAGES_DIR}/${strPackageName}"
  if [ -d "${strPackageDirectory}" ]; then
    strMsg+="The '${strPackageName}' package is already installed.\n"
    strMsg+="This action was aborted."

    shellNS_dialog_set "info" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi



  strMsg+="Do you confirm the installation of the '${strPackageName}' package?"

  shellNS_prompt_set "question" "${strMsg}" "1" "0" "1" "SHELLNS_PROMPT_OPTION_BOOL"
  shellNS_prompt_show

  local p=$(shellNS_prompt_get)
  if [ "${p}" != "1" ]; then
    strMsg+="Installation aborted."

    shellNS_dialog_set "info" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi



  git -C "${SHELLNS_CONFIG_PACKAGES_DIR}" clone "${strURLPackage}"
  if [ ! -d "${strPackageDirectory}" ]; then
    strMsg+="An unexpected error occurred and the installation was not completed."

    shellNS_dialog_set "error" "${strMsg}"
    shellNS_dialog_show
    return 1
  fi



  strMsg+="Installation was successful.\n"
  strMsg+="The '${strPackageName}' package will be loaded from your next session."

  shellNS_dialog_set "ok" "${strMsg}"
  shellNS_dialog_show
  return 0
}