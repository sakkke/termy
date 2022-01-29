#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="termy"
iso_label="TERMY_$(git rev-parse --short HEAD)"
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
  ["/etc/shadow"]="0:0:400"
)
