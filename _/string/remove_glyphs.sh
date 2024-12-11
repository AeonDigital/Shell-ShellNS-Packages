#!/usr/bin/env bash

#
# Converts every string containing glyphs by their respective glyph-free version.
#
# @param string $1
# String that will be converted
#
# @return string
# Prints the result of the conversion performed.
#
# @dependencies
# - iconv
shellNS_string_remove_glyphs() {
  local isCmd=$(command -v iconv &> /dev/null; echo "$?";)
  if [ "${isCmd}" == "0" ]; then
    echo -ne "${1}" | iconv --from-code="UTF8" --to-code="ASCII//TRANSLIT"
  fi
}