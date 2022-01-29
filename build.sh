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

rm -fr "$TARGET"
mkdir "$TARGET"

for profile in ${profiles[@]}; do
  cp -RT "$(realpath "configs/$profile")" "$TARGET"
done

mkarchiso -v "$TARGET"
