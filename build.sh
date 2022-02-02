#!/bin/bash

if ((EUID)); then
  echo 'This script must be run as root'
  exit 4
fi

TARGET=termy
packages=()
profiles=(baseline termy live)

while getopts k:p: OPT; do
  case $OPT in
    k )
      packages+=("$OPTARG")
      ;;

    p )
      profiles+=("$OPTARG")
      ;;

    * )
      exit 3
      ;;
  esac
done

profiles+=(_termy)

rm -fr "$TARGET" configs/_termy
mkdir "$TARGET" configs/_termy

for package in "${packages[@]}"; do
  echo "$package" >> configs/_termy/packages.x86_64
done

for profile in "${profiles[@]}"; do
  if [[ $profile = _termy ]]; then
    sort -uo configs/_termy/packages.x86_64{,}
  elif [[ -f configs/$profile/packages.x86_64 ]]; then
    cat "configs/$profile/packages.x86_64" >> configs/_termy/packages.x86_64
  fi
  cp -RT "$(realpath "configs/$profile")" "$TARGET"
done

mkarchiso -o "$TARGET/out" -v -w "$TARGET/work" "$TARGET"
