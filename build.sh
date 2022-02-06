#!/bin/bash

if ((EUID)); then
  echo 'This script must be run as root'
  exit 4
fi

TARGET=termy
httpd_port=8888
packages=()
profiles=(baseline termy live)

config=$(mktemp)
dbpath1=$(mktemp -d)
dbpath2=$(mktemp -d)
mirrorlist=$(mktemp)
pidfile=$(mktemp)
termy_repo=$(mktemp -d)

trap "rm -fr $config $dbpath1 $dbpath2 $mirrorlist $pidfile $termy_repo" EXIT

cat > $config << /cat
[options]
Architecture = auto
HoldPkg = pacman glibc
LocalFileSigLevel = Optional
SigLevel = DatabaseOptional Required

# Misc options
NoProgressBar
ParallelDownloads = 5

[core]
Include = $mirrorlist

[extra]
Include = $mirrorlist

[community]
Include = $mirrorlist
/cat

cat > $mirrorlist << /cat
Server = http://localhost:$httpd_port
/cat

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
    uniq -u configs/{_termy,baseline}/packages.x86_64 > configs/_termy/airootfs/opt/termy/pkgs
    echo \
      base \
      linux \
      linux-firmware \
      | xargs -n1 >> configs/_termy/airootfs/opt/termy/pkgs
    sort -uo configs/_termy/airootfs/opt/termy/pkgs{,}
    pacman \
      --dbpath $dbpath1 \
      --downloadonly \
      --noconfirm \
      --refresh \
      --sync \
      - < configs/_termy/airootfs/opt/termy/pkgs
    find /var/cache/pacman/pkg -maxdepth 1 -mindepth 1 | xargs -0 -I{} ln -s "{}" $termy_repo
    ln -s /var/lib/pacman/sync/community.db $termy_repo
    ln -s /var/lib/pacman/sync/core.db $termy_repo
    ln -s /var/lib/pacman/sync/extra.db $termy_repo
    bash << /bash & sleep 10
echo \$\$ > $pidfile
darkhttpd $termy_repo --port $httpd_port
/bash
    pid=$(cat $pidfile)
    pacman \
      --cachedir configs/_termy/airootfs/opt/termy/pkg \
      --config $config \
      --dbpath $dbpath2 \
      --downloadonly \
      --noconfirm \
      --sync \
      - < configs/_termy/airootfs/opt/termy/pkgs
    pkill -P $pid
    repo-add -n configs/_termy/airootfs/opt/termy/pkgs/termy.db.tar.gz *.pkg.tar.{xz,zst}
    cat > configs/_termy/pacman.conf << /cat
[options]
Architecture = auto
HoldPkg = pacman glibc
LocalFileSigLevel = Optional
SigLevel = DatabaseOptional Required

# Misc options
NoProgressBar
ParallelDownloads = 5

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[termy]
SigLevel = Optional TrustAll
Server = file://$PWD/configs/_termy/airootfs/opt/termy/pkg
/cat
  elif [[ -f configs/$profile/packages.x86_64 ]]; then
    cat "configs/$profile/packages.x86_64" >> configs/_termy/packages.x86_64
  fi
  cp -RT "$(realpath "configs/$profile")" "$TARGET"
  case "$profile" in
    _termy | baseline | live )
      :
      ;;

    * )
      cp -RT "configs/$profile/airootfs" configs/_termy/airootfs/opt/termy/overlay
      ;;
  esac
done

mkarchiso -o "$TARGET/out" -v -w "$TARGET/work" "$TARGET"
