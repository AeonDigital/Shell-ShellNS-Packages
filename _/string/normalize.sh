#!/usr/bin/env bash

#
# Normalizes a string to be used in secure comparisons.
#
# Will remove any existing \0 characters (null).
# Will convert every string of type "control character" such
# as \r, \n, \t to its respective command.
#
# @param string $1
# string that will be normalized.
#
# @return string
shellNS_string_normalize() {
  local strNormalized="${1//'\0'/}" # remove all null characters
  strNormalized=$(echo -ne "${strNormalized}")


  local -A assocStringCommands
  assocStringCommands['\\n']=$'\n'  # New Line
  assocStringCommands['\\t']=$'\t'  # Tab Horizontal
  assocStringCommands['\\r']=$'\r'  # Carriage Return
  assocStringCommands['\\b']=$'\b'  # Backspace
  assocStringCommands['\\a']=$'\a'  # Alert
  assocStringCommands['\\v']=$'\v'  # Tab Vertical
  assocStringCommands['\\f']=$'\f'  # Form Feed

  local strCmd=""
  local realCmd=""
  for strCmd in "${!assocStringCommands[@]}"; do
    realCmd="${assocStringCommands[${strCmd}]}"
    strNormalized="${strNormalized//${realCmd}/${strCmd}}"
  done

  echo -ne "${strNormalized}"
}
