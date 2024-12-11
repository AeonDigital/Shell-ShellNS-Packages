#!/usr/bin/env bash

#
# Package Install Script





declare -a arrGarbageCollectorFiles=()
declare -a arrGarbageCollectorObjects=()
declare -g dirThisDirectory="$(tmpPath=$(dirname "${BASH_SOURCE[0]}"); realpath "${tmpPath}")"
arrGarbageCollectorObjects+=("dirThisDirectory")

declare -g SHELLNS_INSTALL_DIRECTORY="${HOME}/shellns"
arrGarbageCollectorObjects+=("SHELLNS_INSTALL_DIRECTORY")

declare -gA SHELLNS_CONFIG_CORE_PACKAGES
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Packages"]="https://github.com/AeonDigital/Shell-ShellNS-Packages"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Dialog"]="https://github.com/AeonDigital/Shell-ShellNS-Dialog"



#
# Shows the user an error message.
#
# @param string $1
# Error message.
#
# @return string
shellNS_install_ErrorMessageShow() {
  if [ "${1}" != "" ]; then
    local colorNone="\e[0m"
    local colorErr="\e[1;31m"

    local codeNL=$'\n'
    local strIndent="        "
    strDialogMessage=$(echo -ne "${1}")
    strDialogMessage="${strDialogMessage//${codeNL}/${codeNL}${strIndent}}"

    echo -e "[ ${colorErr}err${colorNone} ] ${strDialogMessage}"
  fi
}
arrGarbageCollectorObjects+=("shellNS_install_ErrorMessageShow")



#
# Downloads a file to and saves it to the current directory where the
# shell is running.
#
# If a file of the same name exists in the same location, the old file
# is first deleted.
#
# Any failure to download will stop the installation.
#
# @param string $1
# Download name.
#
# @param fileName $2
# Name with which the target file will be saved locally.
#
# @param urlFullPath $3
# Full URL to the location where the original file should be downloaded.
#
# @param bool $4
# If '1' will add the downloaded file to the garbage collector and it
# will be deleted at the end of this installation.
#
# @param bool $5
# If '1' will make the file executable.
#
# @param bool $6
# If '1' will load the file to the current context.
# This option will only be used if $4 is '1'
#
# @return status
shellNS_install_DownloadFile() {
  local strDownloadName="${1}"
  local tgtFileName="${2}"
  local tgtURLFullPath="${3}"

  local boolInsertInGarbageCollector="${4}"
  local boolTurnExecutable="${5}"
  local boolLoadToContext="${6}"

  if [ -f "${tgtFileName}" ]; then
    rm "${tgtFileName}"

    if [ -f "${tgtFileName}" ]; then
      strError+="Could not remove the old '${tgtFileName}' file.\n"
      strError+="Check your permissions to proceed.\n\n"
      strError+="This installation was aborted."

      shellNS_install_ErrorMessageShow "${strError}"
      return 1
    fi
  fi


  curl -o "${tgtFileName}" "${tgtURLFullPath}"
  if [ ! -f "${tgtFileName}" ]; then
    strError+="The '${strDownloadName}' could not be downloaded.\n\n"
    strError+="This installation was aborted."

    shellNS_install_ErrorMessageShow "${strError}"
    return 1
  fi


  if [ "${boolInsertInGarbageCollector}" == "1" ]; then
    arrGarbageCollectorFiles+=("${tgtFileName}")
  fi


  if [ "${boolTurnExecutable}" == "1" ]; then
    chmod +x "${tgtFileName}"
    if [ "$?" != "0" ]; then
      strError+="Unable to turns file '${tgtFileName}' executable.\n\n"
      strError+="Check your permissions to proceed.\n\n"
      strError+="This installation was aborted."

      shellNS_install_ErrorMessageShow "${strError}"
      return 1
    fi

    if [ "${boolLoadToContext}" == "1" ]; then
      . "${tgtFileName}"
    fi
  fi
}
arrGarbageCollectorObjects+=("shellNS_install_DownloadFile")



#
# Identifies whether the dialog package is available.
# If it is not, a standalone version of it will be downloaded to proceed with
# this installation.
#
# @return status
shellNS_install_CheckDependencies() {
  local strError=""
  local isCmd=""


  isCmd=$(command -v git &> /dev/null; echo "$?";)
  if [ "${isCmd}" != "0" ]; then
    strError+="Dependency not found: 'git'.\n\n"
    strError+="This installation was aborted."

    shellNS_install_ErrorMessageShow "${strError}"
    return 1
  fi

  isCmd=$(command -v curl &> /dev/null; echo "$?";)
  if [ "${isCmd}" != "0" ]; then
    strError+="Dependency not found: 'curl'.\n\n"
    strError+="This installation was aborted."

    shellNS_install_ErrorMessageShow "${strError}"
    return 1
  fi



  if [ "$(type -t shellNS_dialog_reset)" != "function" ]; then
    local strDownloadName="Dialog Package"
    local strFileName="install_shellns_dialog_standalone.sh"
    local strURLFullPath="https://raw.githubusercontent.com/AeonDigital/Shell-ShellNS-Dialog/refs/heads/main/standalone.sh"

    shellNS_install_DownloadFile "${strDownloadName}" "${strFileName}" "${strURLFullPath}" "1" "1" "1"
    if [ "$?" != "0" ]; then
      return 1
    fi
  fi


  shellNS_dialog_set "ok" "Found Dialog Package"
  shellNS_dialog_show
  return 0
}
arrGarbageCollectorObjects+=("shellNS_install_CheckDependencies")



#
# Identifies the directory where shellNS will be installed.
#
# By default it will be in '${HOME}/shellns' but if the user has the 'XDG'
# directories configured, it will use '${XDG_MAIN_HOME}/apps/shellns'
#
# @return status
shellNS_install_CheckInstallDirectory() {
  if [ "${XDG_MAIN_HOME:+exists}" ]; then
    SHELLNS_INSTALL_DIRECTORY="${XDG_MAIN_HOME}/apps/shellns"
  fi


  if [ -d "${SHELLNS_INSTALL_DIRECTORY}" ]; then
    local strQuestion=""
    strQuestion+="A ShellNS installation has been identified in '${SHELLNS_INSTALL_DIRECTORY}'.\n"
    strQuestion+="If it proceeds, the current installation will be removed entirely and a new one will be made.\n"
    strQuestion+="Any packages that are not in the 'Core group' will be lost and will need to be reinstalled later.\n"
    strQuestion+="Do you confirm the continuation of this action?"

    shellNS_prompt_set "question" "${strQuestion}" "1" "0" "1" "SHELLNS_PROMPT_OPTION_BOOL"
    shellNS_prompt_show

    local p=$(shellNS_prompt_get)
    if [ "${p}" != "1" ]; then
      shellNS_dialog_set "warning" "Installation aborted by the user."
      shellNS_dialog_show
      return 1
    fi

    rm -rf "${SHELLNS_INSTALL_DIRECTORY}"
    if [ "$?" != "0" ]; then
      local strError=""
      strError+="Cannot remove old ShellNS installation in '${SHELLNS_INSTALL_DIRECTORY}'.\n"
      strError+="Check your permissions to proceed.\n\n"
      strError+="This installation was aborted."

      shellNS_dialog_set "error" "${strError}"
      shellNS_dialog_show
      return 1
    fi


    #
    # Cleans the '.bashrc' from previous installations.
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


    shellNS_dialog_set "ok" "Old ShellNS instalation removed."
    shellNS_dialog_show
  fi


  if [ ! -d "${SHELLNS_INSTALL_DIRECTORY}" ]; then
    shellNS_prompt_set "question" "ShellNS will be installed in directory '${SHELLNS_INSTALL_DIRECTORY}'." "1" "0" "1" "SHELLNS_PROMPT_OPTION_BOOL"
    shellNS_prompt_show

    local p=$(shellNS_prompt_get)
    if [ "${p}" != "1" ]; then
      shellNS_dialog_set "warning" "Installation aborted by the user."
      shellNS_dialog_show
      return 1
    fi

    mkdir -p "${SHELLNS_INSTALL_DIRECTORY}/"{packages,storage}
    if [ ! -d "${SHELLNS_INSTALL_DIRECTORY}/packages" ]; then
      local strError=""
      strError+="Cannot create instalation directory in '${SHELLNS_INSTALL_DIRECTORY}'.\n"
      strError+="Check your permissions to proceed.\n\n"
      strError+="This installation was aborted."

      shellNS_dialog_set "error" "${strError}"
      shellNS_dialog_show
      return 1
    fi

    shellNS_dialog_set "ok" "Instalation directory created: '${SHELLNS_INSTALL_DIRECTORY}'."
    shellNS_dialog_show
    return 0
  fi
}
arrGarbageCollectorObjects+=("shellNS_install_CheckInstallDirectory")



#
# Generates the ShellNS boot file
#
# @return status
shellNS_install_CreateInitScript() {
  local strDownloadName="ShellNS Start Script"
  local strFileName="start.sh"
  local strURLFullPath="https://raw.githubusercontent.com/AeonDigital/Shell-ShellNS-Packages/refs/heads/main/install/start.sh"

  cd "${SHELLNS_INSTALL_DIRECTORY}"
  shellNS_install_DownloadFile "${strDownloadName}" "${strFileName}" "${strURLFullPath}" "0" "1" "0"
  if [ "$?" != "0" ]; then
    cd "${dirThisDirectory}"
    return 1
  fi
  cd "${dirThisDirectory}"

  shellNS_dialog_set "ok" "ShellNS Start Script OK!"
  shellNS_dialog_show
  return 0
}
arrGarbageCollectorObjects+=("shellNS_install_CreateInitScript")



#
# Install all Core Packages of ShellNS.
#
# @return status
shellNS_install_InstallCorePackages() {
  local strPackageInstallationDir="${SHELLNS_INSTALL_DIRECTORY}/packages"
  cd "${strPackageInstallationDir}"

  local pkg=""
  local pkgUrl=""
  for pkg in "${!SHELLNS_CONFIG_CORE_PACKAGES[@]}"; do
    shellNS_dialog_set "info" "Downloading package '${pkg}'"
    shellNS_dialog_show

    pkgUrl="${SHELLNS_CONFIG_CORE_PACKAGES[${pkg}]}"
    git clone "${pkgUrl}"

    if [ "$?" != "0" ]; then
      local strError=""
      strError+="Error on download package '${pkg}'.\n"
      strError+="This installation was aborted."

      shellNS_dialog_set "error" "${strError}"
      shellNS_dialog_show
      return 1
    fi

    shellNS_dialog_set "ok" "Package '${pkg}' download success!"
    shellNS_dialog_show
  done

  cd "${dirThisDirectory}"
}
arrGarbageCollectorObjects+=("shellNS_install_InstallCorePackages")



#
# Adds launcher in .bashrc
#
# @return status
shellNS_install_InstallLauncherInBashRC() {
  local strLauncher=""
  strLauncher+="# SHELLNS INI\n"
  strLauncher+="SHELLNS_CONFIG_INTERFACE_LOCALE=\"en-us\"\n"
  strLauncher+=". \"${SHELLNS_INSTALL_DIRECTORY}/start.sh\"\n"
  strLauncher+="# SHELLNS END\n"


  local strQuestion=""
  strQuestion+="Do you want the installer to add an auto-start script\n"
  strQuestion+="for ShellnS in your '.bashrc' file?"

  shellNS_prompt_set "question" "${strQuestion}" "1" "0" "1" "SHELLNS_PROMPT_OPTION_BOOL"
  shellNS_prompt_show

  local p=$(shellNS_prompt_get)
  if [ "${p}" == "1" ]; then
    echo -ne "${strLauncher}"
    echo -ne "${strLauncher}" >> "${HOME}/.bashrc"
    if [ "$?" != "0" ]; then
      local strError=""
      strError+="Couldn't add the auto-start script to your '.bashrc' file.\n"
      strError+="Check your permissions to proceed.\n\n"

      shellNS_dialog_set "error" "${strError}"
      shellNS_dialog_show
    else
      shellNS_dialog_set "ok" "ShellNS auto-start script installed in your '.bashrc' file!"
      shellNS_dialog_show
    fi
  else
    local strInfo=""
    strInfo+="You can manually add the snippet below to your '.bashrc' so that\n"
    strInfo+="ShellNS starts automatically in future sessions.\n\n"
    strInfo+="${strLauncher}"
    shellNS_dialog_set "info" "${strInfo}"
    shellNS_dialog_show
  fi
}
arrGarbageCollectorObjects+=("shellNS_install_InstallLauncherInBashRC")



#
# Removes all files register in garbage collector.
#
# @return status
shellNS_install_GarbageCollectorClear() {
  local it=""

  for it in "${arrGarbageCollectorFiles[@]}"; do
    rm "${it}"
  done
  unset arrGarbageCollectorFiles


  for it in "${arrGarbageCollectorObjects[@]}"; do
    eval "unset \"${it}\""
  done
  unset arrGarbageCollectorObjects
}
arrGarbageCollectorObjects+=("shellNS_install_GarbageCollectorClear")





#
# Perform the ShellNS installation
#
# @return status
shellNS_install() {
  shellNS_install_CheckDependencies
  if [ "$?" != "0" ]; then
    shellNS_install_GarbageCollectorClear
    return 1
  fi

  shellNS_install_CheckInstallDirectory
  if [ "$?" != "0" ]; then
    shellNS_install_GarbageCollectorClear
    return 1
  fi

  shellNS_install_CreateInitScript
  if [ "$?" != "0" ]; then
    shellNS_install_GarbageCollectorClear
    return 1
  fi

  shellNS_install_InstallCorePackages
  if [ "$?" != "0" ]; then
    shellNS_install_GarbageCollectorClear
    return 1
  fi

  shellNS_install_InstallLauncherInBashRC
  if [ "$?" != "0" ]; then
    shellNS_install_GarbageCollectorClear
    return 1
  fi

  shellNS_dialog_set "ok" "The installation was completed successfully!"
  shellNS_dialog_show

  arrGarbageCollectorFiles+=("${BASH_SOURCE[0]}")
  shellNS_install_GarbageCollectorClear
}
shellNS_install