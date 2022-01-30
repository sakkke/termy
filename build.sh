#!/bin/bash

TARGET=termy
profiles=(baseline termy)

while getopts p: OPT; do
  case $OPT in
    p )
      profiles+=("$OPTARG")
      ;;
  esac
done

profiles+=(_termy)

rm -fr "$TARGET" configs/_termy
mkdir "$TARGET" configs/_termy

for profile in ${profiles[@]}; do
  if [[ $profile = _termy ]]; then
    sort -uo configs/_termy/packages.x86_64{,}
  elif [[ -f configs/$profile/packages.x86_64 ]]; then
    cat "configs/$profile/packages.x86_64" >> configs/_termy/packages.x86_64
  fi
  cp -RT "$(realpath "configs/$profile")" "$TARGET"
done

mkarchiso -v "$TARGET"
