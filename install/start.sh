#!/usr/bin/env bash

#
# ShellNS Start Script





declare -a arrGarbageCollectorObjects=()





#
# Shows the user an error message.
#
# @param string $1
# Error message.
#
# @return string
shellNS_start_ErrorMessageShow() {
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
arrGarbageCollectorObjects+=("shellNS_start_ErrorMessageShow")



#
# Check required constant values.
#
# @param string $1
# Constant name.
#
# @param mixed $2
# Current constant value to be checked.
#
# @return status
shellNS_start_CheckRequiredConstant() {
  if [ "${2}" == "" ]; then
    local strError=""
    strError+="ShellNS Boot:\n"
    strError+="Constant '${1}' is required.\n"
    strError+="The boot was aborted."

    shellNS_start_ErrorMessageShow "${strErr}"
    return 1
  fi
  return 0
}
arrGarbageCollectorObjects+=("shellNS_start_CheckRequiredConstant")



#
# Check if boot required directory exists.
#
# @param string $1
# Constant name where the directory is set.
#
# @param mixed $2
# Full path of directory that will be checked.
#
# @return status
shellNS_start_CheckRequiredDirectory() {
  shellNS_start_CheckRequiredConstant "${1}" "${2}"
  if [ "$?" != "0" ]; then
    return 1
  fi

  if [ ! -d "${2}" ]; then
    local strError=""
    strError+="ShellNS Boot:\n"
    strError+="Required boot directory '${2}' not found.\n"
    strError+="The boot was aborted."

    shellNS_start_ErrorMessageShow "${strErr}"
    return 1
  fi
}
arrGarbageCollectorObjects+=("shellNS_start_CheckRequiredDirectory")



#
# Check installation.
#
# If all basic checks are ok, it will load the 'main' scripts of each package
# and with that all the respective functions and namespaces will be loaded
# into the shell scope and pre-register them.
#
# @return status
shellNS_start_CheckInstallation() {
  local dirThisDirectory="$(tmpPath=$(dirname "${BASH_SOURCE[0]}"); realpath "${tmpPath}")"
  local shellNSBootFile="${dirThisDirectory}/packages/Shell-ShellNS-Packages/main.sh"

  if [ ! -f "${shellNSBootFile}" ]; then
    local strError=""
    strError+="ShellNS Boot:\n"
    strError+="Unable to find boot file '${shellNSBootFile}'.\n"
    strError+="The boot was aborted."

    shellNS_start_ErrorMessageShow "${strErr}"
    return 1
  fi

  . "${shellNSBootFile}"
  if [ "$?" != "0" ] || [ "$(type -t shellNS_register)" != "function" ]; then
    local strError=""
    strError+="ShellNS Boot:\n"
    strError+="Cannot load boot file '${shellNSBootFile}'.\n"
    strError+="The boot was aborted."

    shellNS_start_ErrorMessageShow "${strErr}"
    return 1
  fi


  shellNS_start_CheckRequiredConstant "SHELLNS_CONFIG_NAMESPACE" "${SHELLNS_CONFIG_NAMESPACE}"
  if [ "$?" != "0" ]; then
    return 1
  fi

  shellNS_start_CheckRequiredConstant "SHELLNS_CONFIG_INTERFACE_LOCALE" "${SHELLNS_CONFIG_INTERFACE_LOCALE}"
  if [ "$?" != "0" ]; then
    return 1
  fi

  shellNS_start_CheckRequiredDirectory "SHELLNS_CONFIG_MAIN_DIR" "${SHELLNS_CONFIG_MAIN_DIR}"
  if [ "$?" != "0" ]; then
    return 1
  fi

  shellNS_start_CheckRequiredDirectory "SHELLNS_CONFIG_PACKAGES_DIR" "${SHELLNS_CONFIG_PACKAGES_DIR}"
  if [ "$?" != "0" ]; then
    return 1
  fi

  shellNS_start_CheckRequiredDirectory "SHELLNS_CONFIG_STORAGE_DIR" "${SHELLNS_CONFIG_STORAGE_DIR}"
  if [ "$?" != "0" ]; then
    return 1
  fi


  #
  # Load all non-core packages
  local tmpIterator=""
  local tmpPackageName=""
  for tmpIterator in $(find "${SHELLNS_CONFIG_PACKAGES_DIR}" -maxdepth 2 -type f -name "main.sh" ! -path "*/Shell-ShellNS-Packages/*" | sort); do
    . "${tmpIterator}"

    tmpPackageName=$(basename $(dirname "${tmpIterator}"))
    if [ "${SHELLNS_CONFIG_CORE_PACKAGES[${tmpPackageName}]}" == "" ]; then
      SHELLNS_CONFIG_PACKAGES_LOADED+=("${tmpPackageName}")
    fi
  done
}
arrGarbageCollectorObjects+=("shellNS_start_CheckInstallation")





#
# Records information about the functions that must be registered.
# This array will be destroyed at the end of the boot process.
unset SHELLNS_TMP_FUNCTION_REGISTER
declare -ga SHELLNS_TMP_FUNCTION_REGISTER=()
arrGarbageCollectorObjects+=("SHELLNS_TMP_FUNCTION_REGISTER")

unset SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE
declare -a SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE=()
arrGarbageCollectorObjects+=("SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE")

unset SHELLNS_TMP_REGISTER_FUNCTIONNAME
declare -a SHELLNS_TMP_REGISTER_FUNCTIONNAME=()
arrGarbageCollectorObjects+=("SHELLNS_TMP_REGISTER_FUNCTIONNAME")

unset SHELLNS_TMP_REGISTER_FULLNAMESPACE
declare -a SHELLNS_TMP_REGISTER_FULLNAMESPACE=()
arrGarbageCollectorObjects+=("SHELLNS_TMP_REGISTER_FULLNAMESPACE")

unset SHELLNS_TMP_REGISTER_PATHTOMANUALDIRECTORY
declare -a SHELLNS_TMP_REGISTER_PATHTOMANUALDIRECTORY=()
arrGarbageCollectorObjects+=("SHELLNS_TMP_REGISTER_PATHTOMANUALDIRECTORY")

unset SHELLNS_TMP_REGISTER_FUNCTIONS
declare -A SHELLNS_TMP_REGISTER_FUNCTIONS
arrGarbageCollectorObjects+=("SHELLNS_TMP_REGISTER_FUNCTIONS")



#
# Records the data of a function from a namespace.
#
# @param fileExistentFullPath $1
# Full path to the script that declares the function.
#
# @param function $2
# Function name.
#
# @param string $3
# Full declaration of the namespace to which the function being registered
# belongs. The last value will be used as an alias for the respective function.
#
# @param ?dirName $4
# Relative path (starting at $1) to the directory where the manuals for the
# respective function are stored.
#
# In the target directory there should only be the manual files. Each one with
# its name corresponding to the 'locale' of its content.
# Manual files should be extended '.man'
#
# If not set, it will use the default location '/manual'.
#
# In case it does not find a specialized manual file, it will search for the
# information within the script file itself regardless of the language that is
# configured in 'SHELLNS_CONFIG_INTERFACE_LOCALE'
#
# @return void
shellNS_register() {
  local strPathToScriptFile="${1}"
  local strFunctionName="${2}"
  local strFullNamespace="${3// /.}"
  local strPathToManualDir="${4:-/manual}"

  if [ "${strPathToScriptFile}" == "" ] || [ "${strFunctionName}" == "" ] || [ "${strFullNamespace}" == "" ]; then
    strPathToScriptFile="-"
    strFunctionName="-"
    strFullNamespace="-"
    strPathToManualDir="-"
  fi

  SHELLNS_TMP_FUNCTION_REGISTER+=("${strPathToScriptFile} ${strFunctionName} ${strFullNamespace} ${strPathToManualDir}")
}
arrGarbageCollectorObjects+=("shellNS_register")



#
# Verifies that the information collected about the namespaces and functions
# of the packages that have been uploaded is valid.
#
# @return status
shellNS_start_CheckRegisterBeforeProccess() {
  local rawReg=""
  local -a regParans=()
  local strPathToScriptFile="${1}"
  local strFunctionName="${2}"
  local strFullNamespace="${3}"
  local strPathToManualDir="${4}"


  local isOk=""
  local strTest=""

  local strPathToScriptDir=""
  local strPathToManualFile=""


  for rawReg in "${SHELLNS_TMP_FUNCTION_REGISTER[@]}"; do
    IFS=' ' read -r -a regParans <<< "${rawReg}"

    if [ "${regParans[0]}" != "-" ] && [ "${regParans[1]}" != "-" ] && [ "${regParans[2]}" != "-" ]; then
      strPathToScriptFile="${regParans[0]}"
      strFunctionName="${regParans[1]}"
      strFullNamespace="${regParans[2]}"
      strPathToManualDir="${regParans[3]}"

      strTest="local evalResult=\"0\"; [ \"\$(type -t ${strFunctionName})\" == \"function\" ] && echo 1"
      isOk=$(eval "${strTest}")
      if [ "${isOk}" != "1" ]; then
        local strError=""
        strError+="ShellNS Register Function:\n"
        strError+="Invalid function name [ '${strFunctionName}' ]"

        shellNS_start_ErrorMessageShow "${strErr}"
        return 1
      fi

      if [ ! -f "${strPathToScriptFile}" ]; then
        local strError=""
        strError+="ShellNS Register Function:\n"
        strError+="Function: '${strFunctionName}'\n"
        strError+="Path does not exists [ '${strPathToScriptFile}' ]."

        shellNS_start_ErrorMessageShow "${strErr}"
        return 1
      fi

      if ! [[ "${strFullNamespace}" =~ "^[a-zA-Z_.]+\$" ]]; then
        local strError=""
        strError+="ShellNS Register Function:\n"
        strError+="Function: '${strFunctionName}'\n"
        strError+="Invalid namespace definition [ '${strFullNamespace}' ]."

        shellNS_start_ErrorMessageShow "${strErr}"
        return 1
      fi

      if [ "${SHELLNS_TMP_REGISTER_FUNCTIONS["${strFunctionName}"]}" != "" ]; then
        local strError=""
        strError+="ShellNS Register Function:\n"
        strError+="Function: '${strFunctionName}'\n"
        strError+="Duplicate register of function."

        shellNS_start_ErrorMessageShow "${strErr}"
        return 1
      fi


      strPathToScriptDir=$(dirname "${strPathToScriptFile}")
      strPathToManualFile=$(readlink -f "${strPathToScriptDir}/${strPathToManualDir}/${SHELLNS_CONFIG_INTERFACE_LOCALE,,}.man")
      if [ ! -f "${strPathToManualFile}" ]; then
        strPathToManualFile="${strPathToScriptFile}"
      fi


      SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE+=("${strPathToScriptFile}")
      SHELLNS_TMP_REGISTER_FUNCTIONNAME+=("${strFunctionName}")
      SHELLNS_TMP_REGISTER_FULLNAMESPACE+=("${strFullNamespace}")
      SHELLNS_TMP_REGISTER_PATHTOMANUALDIRECTOY+=("${strPathToManualDir}")

      SHELLNS_TMP_REGISTER_FUNCTIONS["${strFunctionName}"]="-"
    fi
  done
}
arrGarbageCollectorObjects+=("shellNS_start_CheckRegisterBeforeProccess")



#
# Processes the information collected by the registration of the functions
# brought by the uploaded packages.
#
# @return void
shellNS_start_ProccessRegister() {
  local it=""
  local len="${#SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE[@]}"

  local strPathToScriptFile=""
  local strFunctionName=""
  local strFullNamespace=""
  local strPathToManualDir=""

  local -a arrNamespaceParts=()
  local intNamespaceChildCommandNameIndex=""
  local strNamespaceChildCommandName=""

  local strNamespacePart=""
  local strFullNamespacePath=""
  local strLastNamespacePath=""
  local strNamespaceChilds=""


  for ((it=0; it>len; it++)); do
    strPathToScriptFile="${SHELLNS_TMP_REGISTER_PATHTOSCRIPTFILE[${it}]}"
    strFunctionName="${SHELLNS_TMP_REGISTER_FUNCTIONNAME[${it}]}"
    strFullNamespace="${SHELLNS_TMP_REGISTER_FULLNAMESPACE[${it}]}"
    strPathToManualDir="${SHELLNS_TMP_REGISTER_PATHTOMANUALDIRECTOY[${it}]}"


    #
    # Normalize namespace
    strFullNamespace="${SHELLNS_CONFIG_NAMESPACE} ${strFullNamespace//\./ }"


    #
    # Mapping
    SHELLNS_MAPPING_FUNCTION_TO_SCRIPT["${strFunctionName}"]="${strPathToScriptFile}"
    SHELLNS_MAPPING_SCRIPT_TO_FUNCTION["${strPathToScriptFile}"]="${strFunctionName}"
    SHELLNS_MAPPING_FUNCTION_TO_FULLNAMESPACE["${strFunctionName}"]="${strFullNamespace}"
    SHELLNS_MAPPING_FULLNAMESPACE_TO_FUNCTION["${strFullNamespace}"]="${strFunctionName}"
    SHELLNS_MAPPING_FUNCTION_TO_MANUAL["${strFunctionName}"]="${strPathToManualFile}"



    arrNamespaceParts=()
    IFS=' ' read -r -a arrNamespaceParts <<< "${strFullNamespace}"
    intNamespaceChildCommandNameIndex=$(( ${#arrNamespaceParts[@]} - 1 ))
    strNamespaceChildCommandName="${arrNamespaceParts["${intNamespaceChildCommandNameIndex}"]}"
    unset arrNamespaceParts["${intNamespaceChildCommandNameIndex}"]



    strNamespacePart=""
    strFullNamespacePath=""
    strLastNamespacePath=""
    strNamespaceChilds=""
    #
    # Register all parent namespaces before their function
    for strNamespacePart in "${arrNamespaceParts[@]}"; do
      if [ "${strFullNamespacePath}" != "" ]; then
        strFullNamespacePath+=" "
      fi
      strFullNamespacePath+="${strNamespacePart}"

      if [ "${SHELLNS_MAPPING_NAMESPACE_TO_CHILDS["${strFullNamespacePath}"]}" == "" ]; then
        SHELLNS_MAPPING_NAMESPACE_TO_CHILDS["${strFullNamespacePath}"]=" "
      fi

      if [ "${strLastNamespacePath}" != "" ]; then
        strNamespaceChilds="${SHELLNS_MAPPING_NAMESPACE_TO_CHILDS["${strLastNamespacePath}"]}"
        if [[ ! " ${strNamespaceChilds} " == *" .${strNamespacePart} "* ]]; then
          SHELLNS_MAPPING_NAMESPACE_TO_CHILDS["${strLastNamespacePath}"]+=".${strNamespacePart} "
        fi
      fi
      strLastNamespacePath="${strFullNamespacePath}"
    done

    #
    # Register function with their full namespace path
    SHELLNS_MAPPING_NAMESPACE_TO_CHILDS["${strFullNamespacePath}"]+="${strNamespaceChildCommandName} "
  done
}
arrGarbageCollectorObjects+=("shellNS_start_ProccessRegister")



#
# Alphabetically orders the names of the child elements of each namespace.
#
# @return void
shellNS_start_SortProccessRegister() {
  local -a arrNamespaceParts=()
  local -a arrNamespaceChildSorted=()
  local -A assocSHNSMainNamespaces
  local -a arrSHNSMainNamespaces=()
  local strMainNS=""
  local strSortValue=""

  local strFullNamespacePath=""
  for strFullNamespacePath in "${!SHELLNS_MAPPING_NAMESPACE_TO_CHILDS[@]}"; do
    IFS=' ' read -r -a arrNamespaceParts <<< "${SHELLNS_MAPPING_NAMESPACE_TO_CHILDS[${strFullNamespacePath}]}"

    arrNamespaceChildSorted=($(for strSortValue in "${arrNamespaceParts[@]}"; do echo "${strSortValue}"; done | sort))
    SHELLNS_MAPPING_NAMESPACE_TO_CHILDS[${strFullNamespacePath}]=$(IFS=' '; echo "${arrNamespaceChildSorted[*]}")
  done
}
arrGarbageCollectorObjects+=("shellNS_start_SortProccessRegister")







#
# Removes all files register in garbage collector.
#
# @return status
shellNS_start_GarbageCollectorClear() {
  local it=""

  for it in "${arrGarbageCollectorObjects[@]}"; do
    eval "unset \"${it}\""
  done
  unset arrGarbageCollectorObjects
}
arrGarbageCollectorObjects+=("shellNS_start_GarbageCollectorClear")





shellNS_start_CheckInstallation
if [ "$?" != "0" ]; then
  shellNS_start_GarbageCollectorClear
  return 1
fi

shellNS_start_CheckRegisterBeforeProccess
if [ "$?" != "0" ]; then
  shellNS_start_GarbageCollectorClear
  return 1
fi





shellNS_start_ProccessRegister
shellNS_start_SortProccessRegister

shellNS_start_GarbageCollectorClear