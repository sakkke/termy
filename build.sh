#!/bin/bash

source makearchiso.config.sh

function show_progress() {
  local lineno=$1
  local script_len=$2
  local line="$(sed -n ${lineno}p "$BASH_SOURCE" | sed 's/\("\|\\\)/\\\1/g')"
  awk -f - << /awk
BEGIN {
  printf \
    "\\033[7;${progress_color}mProgress: [%3d%%]\\033[m %d: \\033[${progress_color}m%s\\033[m\\n",
    $lineno / $script_len * 100,
    $lineno,
    "$line"
}
/awk
}

trap "show_progress \$LINENO $(wc -l < "$BASH_SOURCE")" DEBUG

if ((EUID)); then
  echo 'This script must be run as root'
  exit 4
fi

WORK_DIR=$brand_name.work
httpd_port=8888
packages=()
profiles=(baseline $brand_name live)

config=$(mktemp)
dbpath1=$(mktemp -d)
dbpath2=$(mktemp -d)
live_repo=$(mktemp -d)
mirrorlist=$(mktemp)
pidfile=$(mktemp)

trap "rm -fr $config $dbpath1 $dbpath2 $mirrorlist $pidfile $live_repo" EXIT

cat > $config << /cat
[options]
Architecture = auto
HoldPkg = pacman glibc
LocalFileSigLevel = Optional
SigLevel = Required DatabaseOptional

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

profiles+=(_$brand_name)

rm -fr "$WORK_DIR" configs/_$brand_name
mkdir "$WORK_DIR" configs/_$brand_name
mkdir -p configs/_$brand_name/airootfs/opt/$brand_name

for package in ${packages[@]}; do
  echo "$package" >> configs/_$brand_name/packages.x86_64
done

for profile in ${profiles[@]}; do
  if [[ $profile = _$brand_name ]]; then
    sort -uo configs/_$brand_name/packages.x86_64{,}
    uniq -u configs/{_$brand_name,baseline}/packages.x86_64 > configs/_$brand_name/airootfs/opt/$brand_name/pkgs
    echo \
      base \
      linux \
      linux-firmware \
      | xargs -n1 >> configs/_$brand_name/airootfs/opt/$brand_name/pkgs
    sort -o configs/_$brand_name/airootfs/opt/$brand_name/pkgs{,}
    pacman \
      --config pacman.conf \
      --dbpath $dbpath1 \
      --downloadonly \
      --noconfirm \
      --refresh \
      --sync \
      - < configs/_$brand_name/airootfs/opt/$brand_name/pkgs
    find /var/cache/pacman/pkg -maxdepth 1 -mindepth 1 -print0 | xargs -0I{} ln -s "{}" $live_repo
    ln -s /var/lib/pacman/sync/community.db $live_repo
    ln -s /var/lib/pacman/sync/core.db $live_repo
    ln -s /var/lib/pacman/sync/extra.db $live_repo
    bash << /bash & sleep 10
echo \$\$ > $pidfile
darkhttpd $live_repo --port $httpd_port
/bash
    pid=$(cat $pidfile)
    pacman \
      --cachedir configs/_$brand_name/airootfs/opt/$brand_name/pkg \
      --config $config \
      --dbpath $dbpath2 \
      --downloadonly \
      --noconfirm \
      --refresh \
      --sync \
      - < configs/_$brand_name/airootfs/opt/$brand_name/pkgs
    pkill -P $pid
    repo-add -n configs/_$brand_name/airootfs/opt/$brand_name/pkg/{$brand_name.db.tar.gz,*.pkg.tar.{xz,zst}}
    cat > configs/_$brand_name/pacman.conf << /cat
[options]
Architecture = auto
HoldPkg = pacman glibc
LocalFileSigLevel = Optional
SigLevel = Required DatabaseOptional

# Misc options
NoProgressBar
ParallelDownloads = 5

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[$brand_name]
SigLevel = Optional TrustAll
Server = file://$PWD/configs/_$brand_name/airootfs/opt/$brand_name/pkg
/cat
  elif [[ -f configs/$profile/packages.x86_64 ]]; then
    cat "configs/$profile/packages.x86_64" >> configs/_$brand_name/packages.x86_64
  fi
  cp -RT "$(realpath "configs/$profile")" "$WORK_DIR"
  case "$profile" in
    _$brand_name | baseline | live )
      :
      ;;

    * )
      if [[ -d configs/$profile/airootfs ]]; then
        cp -RT "configs/$profile/airootfs" configs/_$brand_name/airootfs/opt/$brand_name/overlay
      fi
      ;;
  esac
done

mkarchiso -o "$WORK_DIR/out" -v -w "$WORK_DIR/work" "$WORK_DIR"
