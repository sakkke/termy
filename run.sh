#!/bin/bash
source configs/termy/profiledef.sh
image_name="$iso_name-$iso_version-$arch.iso"
run_archiso -i "termy/out/$image_name" $@
