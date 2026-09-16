#!/usr/bin/env bash
set -euo pipefail

# Unified NixOS installer for:
#   slimbox              - UEFI + LUKS2 + Btrfs
#   gamebox              - UEFI + GRUB + LUKS2 + Btrfs
#   raspi5               - Raspberry Pi firmware + unencrypted Btrfs
#   reserver-industrial  - Jetson/JetPack UEFI + LUKS2 + Btrfs
#
# Examples:
#   sudo ./install.sh --profile slimbox
#   sudo ./install.sh --profile gamebox
#   sudo ./install.sh --profile raspi5
#   sudo ./install.sh --profile reserver-industrial
#   sudo ./install.sh --profile slimbox --resume-build
#   sudo ./install.sh --profile gamebox --resume-build
#   sudo ./install.sh --profile raspi5 --resume-build
#   sudo ./install.sh --profile reserver-industrial --resume-build
#
# Environment overrides:
#   NIXOS_DISK=/dev/nvme0n1
#   NIXOS_USER=xychelsea
#   NIXOS_HOST=<hostname used for status/result names only>
#   NIXOS_DIR=/path/to/nixos-config
#   NIXOS_PASSWD_FILE=/persist/secrets/xychelsea.passwd
#   NIXOS_RPI_SRC=/tmp/nixos-raspberrypi-v1.20260801.0

NIXOS_PROFILE=${NIXOS_PROFILE:-}
NIXOS_DISK=${NIXOS_DISK:-/dev/nvme0n1}
NIXOS_USER=${NIXOS_USER:-xychelsea}
NIXOS_HOST=${NIXOS_HOST:-}
NIXOS_ROOT_DIR=${NIXOS_ROOT_DIR:-/mnt}
NIXOS_PART_OPTS=${NIXOS_PART_OPTS:-compress=zstd,noatime,discard=async}
NIXOS_PASSWD_FILE=${NIXOS_PASSWD_FILE:-/persist/secrets/xychelsea.passwd}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
NIXOS_DIR=${NIXOS_DIR:-${SCRIPT_DIR}}
NIXOS_CONFIG=${NIXOS_CONFIG:-${NIXOS_DIR}/configuration.nix}
NIXOS_HM_CONFIG=${NIXOS_HM_CONFIG:-${NIXOS_DIR}/home-manager/home.nix}
NIXOS_HM_MODULES=${NIXOS_HM_MODULES:-${NIXOS_DIR}/home-manager/modules}
NIXOS_ICONS=${NIXOS_ICONS:-${NIXOS_DIR}/icons}
NIXOS_WALLPAPERS=${NIXOS_WALLPAPERS:-${NIXOS_DIR}/wallpapers}
NIXOS_SCRIPTS_DIR=${NIXOS_SCRIPTS_DIR:-${NIXOS_DIR}/scripts}
NIXOS_GTK_THEMES_DIR=${NIXOS_GTK_THEMES_DIR:-${NIXOS_DIR}/themes}
NIXOS_GRUB_THEME_DIR=${NIXOS_GRUB_THEME_DIR:-${NIXOS_DIR}/grub-theme}
NIXOS_VENDOR_DIR=${NIXOS_VENDOR_DIR:-${NIXOS_DIR}/vendor}

NIXOS_CHANNEL_URL=${NIXOS_CHANNEL_URL:-https://nixos.org/channels/nixos-26.05}
NIXOS_HM_CHANNEL_URL=${NIXOS_HM_CHANNEL_URL:-https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz}
NIXOS_CHANNEL_PATH=${NIXOS_CHANNEL_PATH:-/nix/var/nix/profiles/per-user/root/channels/nixos}
NIXOS_HM_CHANNEL_PATH=${NIXOS_HM_CHANNEL_PATH:-/nix/var/nix/profiles/per-user/root/channels/home-manager}

NIXOS_RPI_REPO=${NIXOS_RPI_REPO:-https://github.com/nvmd/nixos-raspberrypi.git}
NIXOS_RPI_REV=${NIXOS_RPI_REV:-v1.20260801.0}
NIXOS_RPI_SRC=${NIXOS_RPI_SRC:-/tmp/nixos-raspberrypi-${NIXOS_RPI_REV}}
NIXOS_RPI_CACHE=${NIXOS_RPI_CACHE:-https://nixos-raspberrypi.cachix.org}
NIXOS_RPI_CACHE_KEY=${NIXOS_RPI_CACHE_KEY:-nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=}

NIXOS_CRYPT_NAME=${NIXOS_CRYPT_NAME:-nixos}
NIXOS_CRYPT_PART=/dev/mapper/${NIXOS_CRYPT_NAME}

DD_WIPE=0
RESUME_BUILD=0

# Set by load_profile/set_partition_paths/setup_storage.
NIXOS_BOOT_DIR=
NIXOS_BOOT_LABEL=
NIXOS_BOOT_PART_NAME=
NIXOS_ROOT_PART_NAME=
NIXOS_ROOT_GPT_TYPE=
NIXOS_BOOT_SPEC=
NIXOS_BOOT_MODE=
NIXOS_BUILD_MODE=
NIXOS_ENCRYPTED=0
NIXOS_STAGE_VENDOR=0
NIXOS_BOOT_PART=
NIXOS_ROOT_PART=
NIXOS_FS_DEVICE=
BUILT_SYSTEM=

RED=$'\e[31m'
GRN=$'\e[32m'
BLU=$'\e[34m'
DIM=$'\e[2m'
RST=$'\e[0m'

step(){ printf "\n${BLU}==>${RST} %s\n" "$*"; }
ok(){ printf "${GRN}✔${RST} %s\n" "$*"; }
warn(){ printf "${RED}✖${RST} %s\n" "$*"; }
run(){ printf "${DIM}$ %s${RST}\n" "$*"; eval "$@"; }

usage() {
  cat <<'EOF_USAGE'
Usage:
  sudo ./install.sh --profile slimbox [--wipe]
  sudo ./install.sh --profile gamebox [--wipe]
  sudo ./install.sh --profile raspi5 [--wipe]
  sudo ./install.sh --profile reserver-industrial [--wipe]
  sudo ./install.sh --profile PROFILE --resume-build

Profiles:
  slimbox              UEFI boot, LUKS2-encrypted Btrfs
  gamebox              UEFI/GRUB boot, LUKS2-encrypted Btrfs
  raspi5               Native Raspberry Pi firmware boot, unencrypted Btrfs
  reserver-industrial  Jetson/JetPack UEFI boot, LUKS2-encrypted Btrfs

Options:
  --profile NAME     Required unless NIXOS_PROFILE is set.
  --disk DEVICE      Override NIXOS_DISK.
  --resume-build     Reuse the existing target and resume from system build.
  --wipe             After partition-table wipe, overwrite the whole disk with
                     random data. This is optional and can take a long time.
  -h, --help         Show this help.

The normal (non-resume) path is destructive: it repartitions NIXOS_DISK.
EOF_USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { warn "--profile requires a value"; exit 2; }
      NIXOS_PROFILE=$2
      shift 2
      ;;
    --profile=*)
      NIXOS_PROFILE=${1#*=}
      shift
      ;;
    --disk)
      [[ $# -ge 2 ]] || { warn "--disk requires a value"; exit 2; }
      NIXOS_DISK=$2
      shift 2
      ;;
    --disk=*)
      NIXOS_DISK=${1#*=}
      shift
      ;;
    --wipe)
      DD_WIPE=1
      shift
      ;;
    --resume-build)
      RESUME_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

declare -A SUBVOL_TO_MOUNTPOINT=(
  ["@"]="/"
  ["@nix"]="/nix"
  ["@persist"]="/persist"
)

declare -A SUBVOL_OPTS=(
  ["@"]="${NIXOS_PART_OPTS}"
  ["@nix"]="${NIXOS_PART_OPTS}"
  ["@persist"]="${NIXOS_PART_OPTS}"
)

SUBVOL_ORDER=( "@" "@nix" "@persist" )

load_profile() {
  case "${NIXOS_PROFILE}" in
    slimbox)
      NIXOS_HOST=${NIXOS_HOST:-slimbox}
      NIXOS_BOOT_DIR=/boot/efi
      NIXOS_BOOT_LABEL=EFI
      NIXOS_BOOT_PART_NAME=ESP
      NIXOS_ROOT_PART_NAME=${NIXOS_CRYPT_NAME}
      NIXOS_ROOT_GPT_TYPE=8309
      NIXOS_BOOT_SPEC=',1GiB,uefi,*'
      NIXOS_BOOT_MODE=uefi
      NIXOS_BUILD_MODE=nixos
      NIXOS_ENCRYPTED=1
      ;;

    gamebox)
      # x86_64 gaming workstation. The tracked configuration uses GRUB in EFI
      # mode with /boot/efi and a LUKS2-encrypted Btrfs root.
      NIXOS_HOST=${NIXOS_HOST:-gamebox}
      NIXOS_BOOT_DIR=/boot/efi
      NIXOS_BOOT_LABEL=EFI
      NIXOS_BOOT_PART_NAME=ESP
      NIXOS_ROOT_PART_NAME=${NIXOS_CRYPT_NAME}
      NIXOS_ROOT_GPT_TYPE=8309
      NIXOS_BOOT_SPEC=',1GiB,uefi,*'
      NIXOS_BOOT_MODE=uefi
      NIXOS_BUILD_MODE=nixos
      NIXOS_ENCRYPTED=1
      ;;

    raspi5)
      NIXOS_HOST=${NIXOS_HOST:-raspi5}
      NIXOS_BOOT_DIR=/boot/firmware
      NIXOS_BOOT_LABEL=FIRMWARE
      NIXOS_BOOT_PART_NAME=FIRMWARE
      NIXOS_ROOT_PART_NAME=nixos
      NIXOS_ROOT_GPT_TYPE=8300
      NIXOS_BOOT_SPEC=',1GiB,uefi'
      NIXOS_BOOT_MODE=raspberry-pi
      NIXOS_BUILD_MODE=raspberry-pi
      NIXOS_ENCRYPTED=0
      ;;

    reserver-industrial)
      # NVIDIA Jetson Orin NX / JetPack branch. Its tracked configuration mounts
      # the EFI filesystem at /boot and imports modules from ./vendor.
      NIXOS_HOST=${NIXOS_HOST:-mediabox}
      NIXOS_BOOT_DIR=/boot
      NIXOS_BOOT_LABEL=EFI
      NIXOS_BOOT_PART_NAME=ESP
      NIXOS_ROOT_PART_NAME=nixos
      NIXOS_ROOT_GPT_TYPE=8309
      NIXOS_BOOT_SPEC=',1GiB,uefi,*'
      NIXOS_BOOT_MODE=uefi
      NIXOS_BUILD_MODE=nixos
      NIXOS_ENCRYPTED=0
      NIXOS_STAGE_VENDOR=1
      ;;

    '')
      warn "A profile is required. Use --profile slimbox, --profile gamebox, --profile raspi5, or --profile reserver-industrial."
      exit 2
      ;;

    *)
      warn "Unknown profile: ${NIXOS_PROFILE}"
      exit 2
      ;;
  esac
}

set_partition_paths() {
  local partsep=""
  [[ "${NIXOS_DISK}" =~ (nvme|mmcblk|loop) ]] && partsep="p"
  NIXOS_BOOT_PART="${NIXOS_DISK}${partsep}1"
  NIXOS_ROOT_PART="${NIXOS_DISK}${partsep}2"
}

set_fs_device() {
  if (( NIXOS_ENCRYPTED )); then
    NIXOS_FS_DEVICE="${NIXOS_CRYPT_PART}"
  else
    NIXOS_FS_DEVICE="${NIXOS_ROOT_PART}"
  fi
}

preflight() {
  step "Preinstall checks (${NIXOS_PROFILE})"

  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    warn "Run as root"
    exit 1
  fi

  set_partition_paths
  set_fs_device

  [ -b "${NIXOS_DISK}" ] || {
    warn "Not a block device: ${NIXOS_DISK}"
    exit 1
  }

  if (( ! RESUME_BUILD )); then
    [ -f "${NIXOS_CONFIG}" ] || {
      warn "Missing ${NIXOS_CONFIG}"
      exit 1
    }

    [ -f "${NIXOS_HM_CONFIG}" ] || {
      warn "Missing ${NIXOS_HM_CONFIG}"
      exit 1
    }

    [ -d "${NIXOS_HM_MODULES}" ] || {
      warn "Missing ${NIXOS_HM_MODULES}"
      exit 1
    }

    if (( NIXOS_STAGE_VENDOR )); then
      [ -d "${NIXOS_VENDOR_DIR}" ] || {
        warn "Missing ${NIXOS_VENDOR_DIR}; ${NIXOS_PROFILE} imports repository vendor modules"
        exit 1
      }
      [ -e "${NIXOS_VENDOR_DIR}/flake-compat/default.nix" ] || {
        warn "Missing ${NIXOS_VENDOR_DIR}/flake-compat/default.nix"
        exit 1
      }
      [ -d "${NIXOS_VENDOR_DIR}/jetpack-nixos" ] || {
        warn "Missing ${NIXOS_VENDOR_DIR}/jetpack-nixos"
        exit 1
      }
    fi
  fi

  local required=(
    awk
    blkid
    blockdev
    btrfs
    findmnt
    grep
    lsblk
    mkfs.btrfs
    mkfs.fat
    mkpasswd
    mountpoint
    nix-build
    nix-channel
    nixos-enter
    nixos-generate-config
    nixos-install
    partprobe
    sfdisk
    sgdisk
    udevadm
    wipefs
  )

  if (( NIXOS_ENCRYPTED )); then
    required+=(cryptsetup)
  fi

  if [ "${NIXOS_BUILD_MODE}" = raspberry-pi ]; then
    required+=(git)
  fi

  local cmd
  for cmd in "${required[@]}"; do
    command -v "${cmd}" >/dev/null || {
      warn "${cmd} is required"
      exit 1
    }
  done

  if ! mkpasswd --method=help 2>&1 | grep -qw yescrypt; then
    warn "mkpasswd does not advertise yescrypt support"
    exit 1
  fi

  ok "Profile: ${NIXOS_PROFILE}"
  ok "Disk: ${NIXOS_DISK}"
  ok "Boot: ${NIXOS_BOOT_MODE} at ${NIXOS_BOOT_DIR}"
  if (( NIXOS_ENCRYPTED )); then
    ok "Root storage: LUKS2 -> Btrfs (${NIXOS_CRYPT_PART})"
  else
    ok "Root storage: unencrypted Btrfs (${NIXOS_ROOT_PART})"
  fi
}

show_holders() {
  step "Inspecting holders on ${NIXOS_DISK}"
  run "lsblk -e7 -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS,PKNAME '${NIXOS_DISK}' 2>/dev/null || true"
  run "findmnt -rn -S '${NIXOS_BOOT_PART}' -o SOURCE,TARGET 2>/dev/null || true"
  run "findmnt -rn -S '${NIXOS_ROOT_PART}' -o SOURCE,TARGET 2>/dev/null || true"
  run "swapon --show || true"
  if (( NIXOS_ENCRYPTED )) && command -v dmsetup >/dev/null; then
    run "dmsetup ls --tree || true"
  fi
}

release_disk_holders() {
  step "Releasing holders of ${NIXOS_DISK}"

  if mountpoint -q "${NIXOS_ROOT_DIR}" 2>/dev/null; then
    run "umount -R '${NIXOS_ROOT_DIR}' || true"
  fi

  while read -r dev; do
    [ -n "${dev}" ] && run "swapoff '${dev}' || true"
  done < <(awk -v d="${NIXOS_DISK}" '$1 ~ "^"d {print $1}' /proc/swaps 2>/dev/null || true)

  if (( NIXOS_ENCRYPTED )) && [ -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup luksClose '${NIXOS_CRYPT_NAME}' || true"
  fi

  if command -v pvs >/dev/null; then
    run "pvscan --cache || true"
    while read -r vg; do
      [ -n "${vg}" ] && run "vgchange -an '${vg}' || true"
    done < <(
      pvs --noheadings -o vg_name,pv_name 2>/dev/null |
        awk -v d="${NIXOS_DISK}" '$2 ~ "^"d {print $1}' |
        sort -u
    )
  fi

  if command -v mdadm >/dev/null; then
    while read -r md; do
      [ -n "${md}" ] && run "mdadm --stop '${md}' || true"
    done < <(awk '/^md[0-9]+/ {print "/dev/"$1}' /proc/mdstat 2>/dev/null || true)
  fi

  run "sync"
  run "udevadm settle || true"
  run "blockdev --rereadpt '${NIXOS_DISK}' || true"
  run "partprobe '${NIXOS_DISK}' || true"
  run "udevadm settle || true"
}

reset_mounts() {
  step "Resetting existing target mounts"

  run "umount -R '${NIXOS_ROOT_DIR}' 2>/dev/null || true"
  run "umount '${NIXOS_BOOT_PART}' 2>/dev/null || true"

  if (( NIXOS_ENCRYPTED )) && [ -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup luksClose '${NIXOS_CRYPT_NAME}' 2>/dev/null || true"
  fi

  run "mkdir -p '${NIXOS_ROOT_DIR}'"
}

wipe_disk() {
  step "Preparing disk for wipe"
  release_disk_holders
  show_holders

  step "Wiping partition tables and signatures"
  run "sgdisk --zap-all '${NIXOS_DISK}'"
  run "wipefs -af '${NIXOS_DISK}'"

  for p in ${NIXOS_DISK}p* ${NIXOS_DISK}[0-9]*; do
    [ -e "$p" ] && run "wipefs -af '$p'"
  done

  if [ "${DD_WIPE}" -eq 1 ]; then
    step "Destructive full-disk overwrite requested"
    echo "Type YES to overwrite every block of ${NIXOS_DISK} with random data."
    read -r CONFIRM
    if [ "${CONFIRM}" = YES ]; then
      run "dd if=/dev/urandom of='${NIXOS_DISK}' bs=4M status=progress conv=fsync || true"
      run "sync"
    else
      ok "Full-disk overwrite skipped"
    fi
  fi
}

partition_disk() {
  step "Ensuring disk is idle before partitioning"
  release_disk_holders
  show_holders

  step "Partitioning ${NIXOS_DISK} for ${NIXOS_PROFILE}"
  printf 'label: gpt\n%s\n,,linux\n' "${NIXOS_BOOT_SPEC}" |
    sfdisk --wipe always --wipe-partitions always "${NIXOS_DISK}"

  run "sgdisk \
    --change-name=1:'${NIXOS_BOOT_PART_NAME}' \
    --typecode=1:EF00 \
    --change-name=2:'${NIXOS_ROOT_PART_NAME}' \
    --typecode=2:'${NIXOS_ROOT_GPT_TYPE}' \
    '${NIXOS_DISK}'"

  run "partprobe '${NIXOS_DISK}'"
  run "udevadm settle"
  set_partition_paths
  set_fs_device

  run "mkfs.fat -F32 -n '${NIXOS_BOOT_LABEL}' '${NIXOS_BOOT_PART}'"
}

open_encrypted_root() {
  if [ ! -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup open '${NIXOS_ROOT_PART}' '${NIXOS_CRYPT_NAME}'"
  fi
}

setup_storage() {
  if (( NIXOS_ENCRYPTED )); then
    step "Creating LUKS2 container"
    if ! cryptsetup isLuks "${NIXOS_ROOT_PART}" >/dev/null 2>&1; then
      run "cryptsetup luksFormat --type luks2 --batch-mode --pbkdf pbkdf2 '${NIXOS_ROOT_PART}'"
    fi
    open_encrypted_root
  fi

  set_fs_device

  step "Creating Btrfs filesystem on ${NIXOS_FS_DEVICE}"
  if ! blkid -s TYPE -o value "${NIXOS_FS_DEVICE}" 2>/dev/null | grep -q '^btrfs$'; then
    run "mkfs.btrfs -f -L nixos '${NIXOS_FS_DEVICE}'"
  fi
}

create_subvolumes() {
  step "Creating Btrfs subvolumes"
  run "mount -o subvolid=5 '${NIXOS_FS_DEVICE}' '${NIXOS_ROOT_DIR}'"

  local sv
  for sv in "${SUBVOL_ORDER[@]}"; do
    if ! btrfs subvolume show "${NIXOS_ROOT_DIR}/${sv}" >/dev/null 2>&1; then
      run "btrfs subvolume create '${NIXOS_ROOT_DIR}/${sv}'"
    fi
  done

  run "umount '${NIXOS_ROOT_DIR}'"
}

mount_subvolumes() {
  step "Mounting target filesystems"

  local root_opts="${SUBVOL_OPTS["@"]:-$NIXOS_PART_OPTS}"
  run "mount -o subvol=@,${root_opts} '${NIXOS_FS_DEVICE}' '${NIXOS_ROOT_DIR}'"

  local sv mp opts
  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "${sv}" = "@" ] && continue
    mp="${SUBVOL_TO_MOUNTPOINT[$sv]}"
    run "mkdir -p '${NIXOS_ROOT_DIR}${mp}'"
  done

  run "mkdir -p '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "mount '${NIXOS_BOOT_PART}' '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"

  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "${sv}" = "@" ] && continue
    mp="${SUBVOL_TO_MOUNTPOINT[$sv]}"
    opts="${SUBVOL_OPTS[$sv]:-$NIXOS_PART_OPTS}"
    run "mount -o subvol=${sv},${opts} '${NIXOS_FS_DEVICE}' '${NIXOS_ROOT_DIR}${mp}'"
  done

  if (( NIXOS_ENCRYPTED )); then
    run "install -d '${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d'"
  fi

  run "install -d '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager'"
  run "install -d '${NIXOS_ROOT_DIR}/persist/projects'"
  run "install -d '${NIXOS_ROOT_DIR}/persist/var/lib/nixos'"
}

prepare_resume_mounts() {
  step "Preparing existing target for resumed build"

  # Remount from a known state. No partitioning or formatting occurs here.
  run "umount -R '${NIXOS_ROOT_DIR}' 2>/dev/null || true"
  run "mkdir -p '${NIXOS_ROOT_DIR}'"

  if (( NIXOS_ENCRYPTED )); then
    [ -b "${NIXOS_ROOT_PART}" ] || {
      warn "Missing encrypted root partition: ${NIXOS_ROOT_PART}"
      exit 1
    }
    open_encrypted_root
  fi

  set_fs_device

  [ -b "${NIXOS_FS_DEVICE}" ] || {
    warn "Missing Btrfs device: ${NIXOS_FS_DEVICE}"
    exit 1
  }

  if ! blkid -s TYPE -o value "${NIXOS_FS_DEVICE}" 2>/dev/null | grep -q '^btrfs$'; then
    warn "${NIXOS_FS_DEVICE} is not a Btrfs filesystem"
    exit 1
  fi

  mount_subvolumes
}

sanitize_hw_cfg() {
  local f="${NIXOS_ROOT_DIR}/persist/etc/nixos/hardware-configuration.nix"
  local tmp="${f}.tmp"

  [ -f "${f}" ] || {
    warn "Missing generated hardware configuration: ${f}"
    exit 1
  }

  # The tracked configuration is authoritative for filesystem topology.
  # Keep generated kernel/initrd/platform detection, and on encrypted hosts keep
  # the generated boot.initrd.luks.devices.<name>.device UUID. Remove only
  # generated fileSystems and swapDevices declarations.
  awk '
    BEGIN { skip_fs = 0; skip_swap = 0 }

    skip_fs {
      if ($0 ~ /^[[:space:]]*};[[:space:]]*$/) skip_fs = 0
      next
    }

    skip_swap {
      if ($0 ~ /;[[:space:]]*$/) skip_swap = 0
      next
    }

    /^[[:space:]]*fileSystems\."/ {
      if ($0 !~ /};[[:space:]]*$/) skip_fs = 1
      next
    }

    /^[[:space:]]*swapDevices[[:space:]]*=/ {
      if ($0 !~ /;[[:space:]]*$/) skip_swap = 1
      next
    }

    { print }
  ' "${f}" > "${tmp}"

  mv "${tmp}" "${f}"
  ok "Removed generated filesystem/swap declarations from hardware-configuration.nix"
}

generate_and_stage_configs() {
  step "Generating hardware configuration and staging repository files"

  run "install -d '${NIXOS_ROOT_DIR}/persist/etc/nixos'"
  run "nixos-generate-config --root '${NIXOS_ROOT_DIR}' --dir '${NIXOS_ROOT_DIR}/persist/etc/nixos/'"
  sanitize_hw_cfg

  run "install -d '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager'"
  run "cp -f '${NIXOS_CONFIG}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix'"
  run "cp -f '${NIXOS_HM_CONFIG}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/home.nix'"
  run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/modules'"
  run "cp -a '${NIXOS_HM_MODULES}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/modules'"

  if (( NIXOS_STAGE_VENDOR )); then
    step "Staging repository vendor modules for ${NIXOS_PROFILE}"
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/vendor'"
    run "cp -a '${NIXOS_VENDOR_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/vendor'"
  fi

  run "install -d '${NIXOS_ROOT_DIR}/etc'"
  run "ln -sfn '/persist/etc/nixos' '${NIXOS_ROOT_DIR}/etc/nixos'"

  run "ln -sfn '/persist/etc/nixos/home-manager/home.nix' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/home.nix'"
  run "ln -sfn '/persist/etc/nixos/home-manager/modules' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/modules'"
  run "ln -sfn '/projects' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/Projects'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.bash_history'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.zsh_history'"

  if [ -d "${NIXOS_SCRIPTS_DIR}" ]; then
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/scripts'"
    run "cp -a '${NIXOS_SCRIPTS_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/scripts'"
  fi
  if [ -d "${NIXOS_WALLPAPERS}" ]; then
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers'"
    run "cp -a '${NIXOS_WALLPAPERS}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers'"
  fi
  if [ -d "${NIXOS_ICONS}" ]; then
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/icons'"
    run "cp -a '${NIXOS_ICONS}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/icons'"
  fi
  if [ -d "${NIXOS_GTK_THEMES_DIR}" ]; then
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/themes'"
    run "cp -a '${NIXOS_GTK_THEMES_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/themes'"
  fi
  if [ -d "${NIXOS_GRUB_THEME_DIR}" ]; then
    run "rm -rf '${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme'"
    run "cp -a '${NIXOS_GRUB_THEME_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme'"
  fi
}

seed_channels() {
  step "Seeding installer Nix channels"
  run "nix-channel --add '${NIXOS_CHANNEL_URL}' nixos"
  run "nix-channel --add '${NIXOS_HM_CHANNEL_URL}' home-manager"
  run "nix-channel --update"
}

seed_target_channels() {
  step "Seeding Nix and Home Manager channels inside the target"

  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- sh -lc \
    'nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
     nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
     nix-channel --update'"

  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- sh -lc \
    'id ${NIXOS_USER} >/dev/null 2>&1 && \
     su - ${NIXOS_USER} -c \
       \"nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
        nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
        nix-channel --update\" || true'"
}

add_initrd_keyfile() {
  (( NIXOS_ENCRYPTED )) || return 0

  step "Ensuring initrd LUKS keyfile is enrolled"

  local key="${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d/cryptroot.key"
  run "install -d -m 0700 '${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d'"

  if [ ! -e "${key}" ]; then
    run "dd if=/dev/urandom of='${key}' bs=64 count=1 status=none"
    run "chmod 0400 '${key}'"
  fi

  if cryptsetup open --test-passphrase --key-file "${key}" "${NIXOS_ROOT_PART}" >/dev/null 2>&1; then
    ok "Initrd keyfile is already enrolled in LUKS"
  else
    run "cryptsetup luksAddKey '${NIXOS_ROOT_PART}' '${key}'"
  fi
}

fix_persistent_home() {
  step "Ensuring ownership of persistent home"
  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- sh -lc \
    'mkdir -p /home/${NIXOS_USER} /persist/home/${NIXOS_USER}; \
     chown -R ${NIXOS_USER}:users /persist/home/${NIXOS_USER} /persist/etc/nixos/home-manager'"
}

build_system_nixos() {
  local config_path=$1
  local result_link=$2

  [ -e "${NIXOS_CHANNEL_PATH}/nixos/default.nix" ] || {
    warn "NixOS channel is not available at ${NIXOS_CHANNEL_PATH}"
    exit 1
  }

  [ -e "${NIXOS_HM_CHANNEL_PATH}" ] || {
    warn "Home Manager channel is not available at ${NIXOS_HM_CHANNEL_PATH}"
    exit 1
  }

  step "Building ${NIXOS_PROFILE} NixOS system with classic nix-build"
  run "nix-build '${NIXOS_CHANNEL_PATH}/nixos' \
    -A system \
    -I 'nixpkgs=${NIXOS_CHANNEL_PATH}' \
    -I 'home-manager=${NIXOS_HM_CHANNEL_PATH}' \
    -I 'nixos-config=${config_path}' \
    -o '${result_link}'"
}

build_system_raspberry_pi() {
  local config_path=$1
  local result_link=$2
  local eval_expr="/tmp/nixos-${NIXOS_PROFILE}-system.nix"

  step "Preparing Raspberry Pi 5 NixOS module set"
  run "rm -rf '${NIXOS_RPI_SRC}'"
  run "git clone --depth 1 --branch '${NIXOS_RPI_REV}' '${NIXOS_RPI_REPO}' '${NIXOS_RPI_SRC}'"

  [ -f "${NIXOS_RPI_SRC}/default.nix" ] || {
    warn "nixos-raspberrypi checkout is missing default.nix"
    exit 1
  }

  cat > "${eval_expr}" <<'EOF_RPI_SYSTEM'
{ rpiSrc, configPath }:

let
  rpi = import (builtins.toPath rpiSrc);

  system = rpi.lib.nixosSystem {
    modules = [
      (
        { lib, pkgs, nixos-raspberrypi, ... }:
        {
          imports = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-5.base
            raspberry-pi-5.page-size-16k
          ];

          # Until these settings live in the raspi5 configuration itself,
          # make the target unambiguously Pi-native here.
          boot.kernelPackages = lib.mkForce
            nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi5;

          # rustup 1.29.0 builds on aarch64 in this environment but its package
          # check currently fails. Keep rustup installed while skipping only
          # that package's check phase.
          nixpkgs.overlays = lib.mkAfter [
            (final: prev: {
              rustup = prev.rustup.overrideAttrs (_old: {
                doCheck = false;
              });
            })
          ];

          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

          boot.loader.raspberry-pi = {
            enable = true;
            bootloader = lib.mkForce "kernel";
            firmwarePath = "/boot/firmware";
          };

          fileSystems."/boot".enable = lib.mkForce false;
          fileSystems."/boot/firmware" = {
            device = "/dev/disk/by-label/FIRMWARE";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
          };

          # Avoid pulling the out-of-tree ZFS module into the Pi vendor kernel.
          boot.supportedFilesystems.zfs = lib.mkForce false;
          boot.zfs.extraPools = lib.mkForce [ ];
        }
      )

      (builtins.toPath configPath)
    ];
  };
in
system.config.system.build.toplevel
EOF_RPI_SYSTEM

  step "Building Raspberry Pi 5 NixOS system with classic nix-build"
  run "nix-build '${eval_expr}' \
    --argstr rpiSrc '${NIXOS_RPI_SRC}' \
    --argstr configPath '${config_path}' \
    -I 'nixpkgs=${NIXOS_CHANNEL_PATH}' \
    -I 'home-manager=${NIXOS_HM_CHANNEL_PATH}' \
    --option extra-substituters '${NIXOS_RPI_CACHE}' \
    --option extra-trusted-public-keys '${NIXOS_RPI_CACHE_KEY}' \
    -o '${result_link}'"
}

build_system() {
  local config_path="${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix"
  local result_link="/tmp/nixos-${NIXOS_PROFILE}-system"

  [ -f "${config_path}" ] || {
    warn "Staged NixOS configuration is missing: ${config_path}"
    exit 1
  }

  run "rm -f '${result_link}'"

  case "${NIXOS_BUILD_MODE}" in
    nixos)
      build_system_nixos "${config_path}" "${result_link}"
      ;;
    raspberry-pi)
      build_system_raspberry_pi "${config_path}" "${result_link}"
      ;;
    *)
      warn "Unknown build mode: ${NIXOS_BUILD_MODE}"
      exit 1
      ;;
  esac

  BUILT_SYSTEM=$(readlink -f "${result_link}")
  [ -n "${BUILT_SYSTEM}" ] && [ -e "${BUILT_SYSTEM}" ] || {
    warn "Failed to resolve built NixOS system closure"
    exit 1
  }
}

install_system() {
  build_system

  ok "Built ${NIXOS_PROFILE} system: ${BUILT_SYSTEM}"

  step "Running nixos-install with the prebuilt system closure"
  run "nixos-install \
    --root '${NIXOS_ROOT_DIR}' \
    --system '${BUILT_SYSTEM}' \
    --no-channel-copy \
    --no-root-passwd"
}

verify_uefi() {
  step "Verifying EFI system partition and UEFI boot entry"

  run "mountpoint -q '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "findmnt '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "blkid '${NIXOS_BOOT_PART}'"

  if [ ! -d /sys/firmware/efi ]; then
    warn "Installer was not booted through UEFI; firmware boot-entry verification skipped"
    return 0
  fi

  run "mountpoint -q /sys/firmware/efi/efivars || mount -t efivarfs efivarfs /sys/firmware/efi/efivars"
  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- nix-shell -p efibootmgr --run 'efibootmgr -v'"
}

verify_raspberry_pi() {
  step "Verifying Raspberry Pi firmware partition"

  run "mountpoint -q '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "findmnt '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "blkid '${NIXOS_BOOT_PART}'"
  run "find '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}' -maxdepth 2 -type f -printf '%P\\n' | sort | head -100"
}

verify_boot() {
  case "${NIXOS_BOOT_MODE}" in
    uefi)
      verify_uefi
      ;;
    raspberry-pi)
      verify_raspberry_pi
      ;;
    *)
      warn "Unknown boot mode: ${NIXOS_BOOT_MODE}"
      exit 1
      ;;
  esac
}

create_user_password_file() {
  local target="${NIXOS_ROOT_DIR}${NIXOS_PASSWD_FILE}"
  local target_dir
  local pw1 pw2 hash

  target_dir=$(dirname -- "${target}")

  if (( RESUME_BUILD )) && [ -s "${target}" ]; then
    ok "Reusing existing password hash at ${NIXOS_PASSWD_FILE}"
    return 0
  fi

  step "Creating yescrypt password hash for ${NIXOS_USER}"

  while :; do
    read -rs -p "Enter new password for ${NIXOS_USER}: " pw1 < /dev/tty
    echo
    read -rs -p "Confirm password: " pw2 < /dev/tty
    echo
    if [[ "${pw1}" == "${pw2}" && -n "${pw1}" ]]; then
      break
    fi
    warn "Passwords did not match or were empty. Try again."
  done

  # Read the password from stdin so it never appears in argv/process listings.
  hash=$(printf '%s\n' "${pw1}" | mkpasswd --method=yescrypt --stdin)
  unset pw1 pw2

  if [[ "${hash}" != '$y$'* ]]; then
    unset hash
    warn "mkpasswd did not return a yescrypt hash"
    exit 1
  fi

  run "install -d -m 0700 '${target_dir}'"

  # Avoid run/eval here: the hash should not be printed in installer output.
  (
    umask 077
    printf '%s\n' "${hash}" > "${target}"
  )
  chmod 0600 "${target}"
  unset hash

  ok "Created ${NIXOS_PASSWD_FILE} using yescrypt"
}

profile_prepare_for_build() {
  if (( NIXOS_ENCRYPTED )); then
    add_initrd_keyfile
  fi
}

main() {
  load_profile
  preflight

  if (( RESUME_BUILD )); then
    step "Resuming installation; partitioning and formatting are left untouched"
    prepare_resume_mounts
    seed_channels
    create_user_password_file
    profile_prepare_for_build
    install_system
    fix_persistent_home
    seed_target_channels
    verify_boot
    ok "${NIXOS_PROFILE} installation complete."
    return
  fi

  reset_mounts
  wipe_disk
  partition_disk
  setup_storage
  create_subvolumes
  mount_subvolumes
  generate_and_stage_configs
  seed_channels
  create_user_password_file
  profile_prepare_for_build
  install_system
  fix_persistent_home
  seed_target_channels
  verify_boot

  ok "${NIXOS_PROFILE} installation complete."
}

main "$@"
