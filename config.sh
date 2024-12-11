#!/usr/bin/env bash

#
# Main namespace.
if [ ! "${SHELLNS_CONFIG_NAMESPACE:+exists}" ]; then
  readonly SHELLNS_CONFIG_NAMESPACE="shns"
fi



#
# Defines the language to be used in the interface with the user.
# This only affects packets that bring data to serve the indicated location.
if [ ! "${SHELLNS_CONFIG_INTERFACE_LOCALE:+exists}" ]; then
  readonly SHELLNS_CONFIG_INTERFACE_LOCALE="en-us"
fi



#
# Directory where the 'ShellNS' is installed.
if [ ! "${SHELLNS_CONFIG_MAIN_DIR:+exists}" ]; then
  readonly SHELLNS_CONFIG_MAIN_DIR="$(tmpPath=$(dirname $(dirname $(dirname "${BASH_SOURCE[0]}"))); realpath "${tmpPath}")"
fi
#
# Directory where ShellNS Packages are located.
if [ ! "${SHELLNS_CONFIG_PACKAGES_DIR:+exists}" ]; then
  readonly SHELLNS_CONFIG_PACKAGES_DIR="${SHELLNS_CONFIG_MAIN_DIR}/packages"
fi
#
# Directory where package data files should be stored.
#
# Ideally, within this location, each package should have its own directory
# defined with its same name.
if [ ! "${SHELLNS_CONFIG_STORAGE_DIR:+exists}" ]; then
  readonly SHELLNS_CONFIG_STORAGE_DIR="${SHELLNS_CONFIG_MAIN_DIR}/storage"
fi



#
# Location where processed manual data is stored.
if [ ! "${SHELLNS_CONFIG_MANUALS_STORAGE_DIR:+exists}" ]; then
  readonly SHELLNS_CONFIG_MANUALS_STORAGE_DIR="${SHELLNS_CONFIG_STORAGE_DIR}/${SHELLNS_CONFIG_INTERFACE_LOCALE,,}"
fi




#
# Associative array with all core package names and URLs.
unset SHELLNS_CONFIG_CORE_PACKAGES
declare -gA SHELLNS_CONFIG_CORE_PACKAGES
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Packages"]="https://github.com/AeonDigital/Shell-ShellNS-Packages"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Log"]="https://github.com/AeonDigital/Shell-ShellNS-Log"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Dialog"]="https://github.com/AeonDigital/Shell-ShellNS-Dialog"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Result"]="https://github.com/AeonDigital/Shell-ShellNS-Result"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Output"]="https://github.com/AeonDigital/Shell-ShellNS-Output"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Types"]="https://github.com/AeonDigital/Shell-ShellNS-Types"
SHELLNS_CONFIG_CORE_PACKAGES["Shell-ShellNS-Manual"]="https://github.com/AeonDigital/Shell-ShellNS-Manual"



#
# Associative array thats register all Non-Core Packages loaded.
unset SHELLNS_CONFIG_PACKAGES_LOADED
declare -ga SHELLNS_CONFIG_PACKAGES_LOADED=()



#
# Associative array that maps registered functions to their respective
# script files.
unset SHELLNS_MAPPING_FUNCTION_TO_SCRIPT
declare -gA SHELLNS_MAPPING_FUNCTION_TO_SCRIPT
#
# Associative array that maps each registered role with the location of its
# respective manual to the currently configured location.
unset SHELLNS_MAPPING_FUNCTION_TO_MANUAL
declare -gA SHELLNS_MAPPING_FUNCTION_TO_MANUAL
#
# Associative array that maps the loaded scripts and their respective
# functions.
unset SHELLNS_MAPPING_SCRIPT_TO_FUNCTION
declare -gA SHELLNS_MAPPING_SCRIPT_TO_FUNCTION
#
# Associative array that maps registered functions to their namespaces
# in full format.
unset SHELLNS_MAPPING_FUNCTION_TO_FULLNAMESPACE
declare -gA SHELLNS_MAPPING_FUNCTION_TO_FULLNAMESPACE
#
# Associative array that maps each namespace to its associated function.
unset SHELLNS_MAPPING_FULLNAMESPACE_TO_FUNCTION
declare -gA SHELLNS_MAPPING_FULLNAMESPACE_TO_FUNCTION
#
# Associative array that maps each namespace to its child components.
unset SHELLNS_MAPPING_NAMESPACE_TO_CHILDS
declare -gA SHELLNS_MAPPING_NAMESPACE_TO_CHILDS