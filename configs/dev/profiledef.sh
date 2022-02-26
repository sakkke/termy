#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="termy"
iso_label="TERMY_$(git rev-parse --short HEAD | tr [:lower:] [:upper:])"
iso_publisher="termy <https://github.com/sakkke/termy>"
iso_application="termy"
iso_version="$(git rev-parse --short HEAD)"
install_dir="termy"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlz4')
file_permissions=(
  ["/etc/gshadow"]="0:0:400"
  ["/etc/shadow"]="0:0:400"
  ["/etc/skel/.fehbg"]="0:0:754"
  ["/etc/skel/.xinitrc"]="0:0:755"
  ["/opt/termy/bin/termy-install"]="0:0:755"
)
