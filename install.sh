#!/usr/bin/env bash
set -euo pipefail

NIXOS_DISK=${NIXOS_DISK:-/dev/nvme0n1}
NIXOS_USER=${NIXOS_USER:-xychelsea}
NIXOS_HOST=${NIXOS_HOST:-slimbox}

NIXOS_BOOT_DIR=/boot/efi
NIXOS_ROOT_DIR=/mnt
NIXOS_PART_OPTS="compress=zstd,noatime,discard=async"
NIXOS_DIR=${PWD}
NIXOS_CONFIG=${NIXOS_DIR}/configuration.nix
NIXOS_HM_CONFIG=${NIXOS_DIR}/home-manager/home.nix
NIXOS_HM_MODULES=${NIXOS_DIR}/home-manager/modules
NIXOS_ICONS=${NIXOS_DIR}/icons
NIXOS_WALLPAPERS=${NIXOS_DIR}/wallpapers
NIXOS_SCRIPTS_DIR=${NIXOS_DIR}/scripts
NIXOS_GTK_THEMES_DIR=${NIXOS_DIR}/themes
NIXOS_GRUB_THEME_DIR=${NIXOS_DIR}/grub-theme

NIXOS_CHANNEL_URL=https://nixos.org/channels/nixos-26.05
NIXOS_HM_CHANNEL_URL=https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz
NIXOS_CHANNEL_PATH=/nix/var/nix/profiles/per-user/root/channels/nixos
NIXOS_HM_CHANNEL_PATH=/nix/var/nix/profiles/per-user/root/channels/home-manager

NIXOS_CRYPT_NAME=nixos
NIXOS_CRYPT_PART=/dev/mapper/${NIXOS_CRYPT_NAME}

DD_WIPE=0
RESUME_BUILD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --wipe)
      DD_WIPE=1
      shift
      ;;
    --resume-build)
      RESUME_BUILD=1
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
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

RED=$'\e[31m'
GRN=$'\e[32m'
BLU=$'\e[34m'
DIM=$'\e[2m'
RST=$'\e[0m'

step(){ printf "\n${BLU}==>${RST} %s\n" "$*"; }
ok(){ printf "${GRN}✔${RST} %s\n" "$*"; }
warn(){ printf "${RED}✖${RST} %s\n" "$*"; }
run(){ printf "${DIM}$ %s${RST}\n" "$*"; eval "$@"; }

set_partition_paths() {
  local partsep=""
  [[ "${NIXOS_DISK}" =~ (nvme|mmcblk|loop) ]] && partsep="p"
  NIXOS_BOOT_PART="${NIXOS_DISK}${partsep}1"
  NIXOS_ROOT_PART="${NIXOS_DISK}${partsep}2"
}

preflight() {
  step "Preinstall checks"

  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    warn "Run as root"
    exit 1
  fi

  set_partition_paths

  [ -b "${NIXOS_DISK}" ] || {
    warn "Not a block device: ${NIXOS_DISK}"
    exit 1
  }

  [ -f "${NIXOS_CONFIG}" ] || {
    warn "Missing ${NIXOS_CONFIG}"
    exit 1
  }

  [ -f "${NIXOS_HM_CONFIG}" ] || {
    warn "Missing ${NIXOS_HM_CONFIG}"
    exit 1
  }

  local required=(
    btrfs
    mkfs.btrfs
    mkfs.fat
    cryptsetup
    sfdisk
    sgdisk
    wipefs
    partprobe
    udevadm
    blockdev
    nixos-generate-config
    nixos-install
    nixos-enter
    nix-build
    nix-channel
    mountpoint
  )

  local cmd
  for cmd in "${required[@]}"; do
    command -v "${cmd}" >/dev/null || {
      warn "${cmd} is required"
      exit 1
    }
  done

  ok "Using disk ${NIXOS_DISK}"
}

show_holders() {
  step "Inspecting holders on ${NIXOS_DISK}"
  run "lsblk -e7 -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS,PKNAME '${NIXOS_DISK}' ${NIXOS_DISK}p* 2>/dev/null || true"
  run "findmnt -rn -S '^${NIXOS_DISK}(|p[0-9]+)$' -o SOURCE,TARGET || true"
  run "swapon --show || true"
  command -v dmsetup >/dev/null && run "dmsetup ls --tree || true"
}

release_disk_holders() {
  step "Releasing all holders of ${NIXOS_DISK}"

  while read -r tgt; do
    [ -n "${tgt}" ] && run "umount -R '${tgt}' || true"
  done < <(findmnt -rn -S "^${NIXOS_DISK}(|p[0-9]+)$" -o TARGET 2>/dev/null || true)

  if mountpoint -q "${NIXOS_ROOT_DIR}" 2>/dev/null; then
    run "umount -R '${NIXOS_ROOT_DIR}' || true"
  fi

  while read -r dev; do
    [ -n "${dev}" ] && run "swapoff '${dev}' || true"
  done < <(awk -v d="${NIXOS_DISK}" '$1 ~ "^"d {print $1}' /proc/swaps 2>/dev/null || true)

  if [ -e "${NIXOS_CRYPT_PART}" ]; then
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
  step "Resetting any existing mounts and LUKS mappings"

  run "umount -R '${NIXOS_ROOT_DIR}' 2>/dev/null || true"
  run "umount '${NIXOS_BOOT_PART}' 2>/dev/null || true"

  if [ -e "${NIXOS_CRYPT_PART}" ]; then
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
    step "Destructive overwrite requested"
    echo "Are you sure you want to permanently overwrite data in ${NIXOS_DISK}? Type YES to continue."
    read -r CONFIRM
    if [ "${CONFIRM}" = "YES" ]; then
      run "dd if=/dev/urandom of='${NIXOS_DISK}' bs=4M status=progress conv=fsync || true"
      run "sync"
    else
      ok "Data overwrite skipped"
    fi
  fi
}

partition_with_sfdisk() {
  step "Ensuring disk is idle before partitioning"
  release_disk_holders
  show_holders

  step "Partitioning with sfdisk"
  sfdisk --wipe always --wipe-partitions always "${NIXOS_DISK}" <<EOF_PARTITIONS
label: gpt
,1GiB,uefi,*
,,linux
EOF_PARTITIONS

  run "sgdisk --change-name=1:ESP --typecode=1:EF00 --change-name=2:${NIXOS_CRYPT_NAME} --typecode=2:8309 '${NIXOS_DISK}'"
  run "partprobe '${NIXOS_DISK}'"
  run "udevadm settle"

  set_partition_paths

  run "mkfs.fat -F32 -n EFI '${NIXOS_BOOT_PART}'"
}

setup_encryption_and_btrfs() {
  step "Creating LUKS2 container and Btrfs filesystem"

  if ! cryptsetup isLuks "${NIXOS_ROOT_PART}" >/dev/null 2>&1; then
    run "cryptsetup luksFormat --type luks2 --batch-mode --pbkdf pbkdf2 '${NIXOS_ROOT_PART}'"
  fi

  if [ ! -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup open '${NIXOS_ROOT_PART}' '${NIXOS_CRYPT_NAME}'"
  fi

  if ! blkid -s TYPE -o value "${NIXOS_CRYPT_PART}" 2>/dev/null | grep -q '^btrfs$'; then
    run "mkfs.btrfs -f -L nixos '${NIXOS_CRYPT_PART}'"
  fi
}

create_subvolumes() {
  step "Creating Btrfs subvolumes from manifest"

  run "mount -o subvolid=5 '${NIXOS_CRYPT_PART}' '${NIXOS_ROOT_DIR}'"

  if ! btrfs subvolume show "${NIXOS_ROOT_DIR}/@" >/dev/null 2>&1; then
    run "btrfs subvolume create '${NIXOS_ROOT_DIR}/@'"
  fi

  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "$sv" = "@" ] && continue
    if ! btrfs subvolume show "${NIXOS_ROOT_DIR}/${sv}" >/dev/null 2>&1; then
      run "btrfs subvolume create '${NIXOS_ROOT_DIR}/${sv}'"
    fi
  done

  run "umount '${NIXOS_ROOT_DIR}'"
}

mount_subvolumes() {
  step "Mounting subvolumes"

  local root_opts="${SUBVOL_OPTS["@"]:-$NIXOS_PART_OPTS}"
  run "mount -o subvol=@,${root_opts} '${NIXOS_CRYPT_PART}' '${NIXOS_ROOT_DIR}'"

  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "$sv" = "@" ] && continue
    local mp="${SUBVOL_TO_MOUNTPOINT[$sv]}"
    run "mkdir -p '${NIXOS_ROOT_DIR}${mp}'"
  done

  run "mkdir -p '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "mount '${NIXOS_BOOT_PART}' '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"

  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "$sv" = "@" ] && continue
    local mp="${SUBVOL_TO_MOUNTPOINT[$sv]}"
    local opts="${SUBVOL_OPTS[$sv]:-$NIXOS_PART_OPTS}"
    run "mount -o subvol=${sv},${opts} '${NIXOS_CRYPT_PART}' '${NIXOS_ROOT_DIR}${mp}'"
  done

  run "install -d '${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d'"
  run "install -d '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager'"
  run "install -d '${NIXOS_ROOT_DIR}/persist/projects'"
  run "install -d '${NIXOS_ROOT_DIR}/persist/var/lib/nixos'"
}

prepare_resume_mounts() {
  step "Preparing encrypted target mounts for resumed build"

  if [ ! -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup open '${NIXOS_ROOT_PART}' '${NIXOS_CRYPT_NAME}'"
  fi

  run "mkdir -p '${NIXOS_ROOT_DIR}'"

  if ! mountpoint -q "${NIXOS_ROOT_DIR}"; then
    local root_opts="${SUBVOL_OPTS["@"]:-$NIXOS_PART_OPTS}"
    run "mount -o subvol=@,${root_opts} '${NIXOS_CRYPT_PART}' '${NIXOS_ROOT_DIR}'"
  fi

  for sv in "${SUBVOL_ORDER[@]}"; do
    [ "$sv" = "@" ] && continue
    local mp="${SUBVOL_TO_MOUNTPOINT[$sv]}"
    local opts="${SUBVOL_OPTS[$sv]:-$NIXOS_PART_OPTS}"
    run "mkdir -p '${NIXOS_ROOT_DIR}${mp}'"
    if ! mountpoint -q "${NIXOS_ROOT_DIR}${mp}"; then
      run "mount -o subvol=${sv},${opts} '${NIXOS_CRYPT_PART}' '${NIXOS_ROOT_DIR}${mp}'"
    fi
  done

  run "mkdir -p '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  if ! mountpoint -q "${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}"; then
    run "mount '${NIXOS_BOOT_PART}' '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  fi
}

sanitize_hw_cfg() {
  local f="${NIXOS_ROOT_DIR}/persist/etc/nixos/hardware-configuration.nix"
  local tmp="${f}.tmp"

  [ -f "${f}" ] || {
    warn "Missing generated hardware configuration: ${f}"
    exit 1
  }

  # configuration.nix owns the filesystem topology. Keep generated hardware
  # detection (including boot.initrd.luks.devices.<name>.device, when emitted)
  # but remove generated fileSystems and swapDevices declarations so they do
  # not compete with the tracked Btrfs/tmpfs configuration.
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
  step "Generating NixOS hardware config and staging repository files"

  run "install -d '${NIXOS_ROOT_DIR}/persist/etc/nixos'"
  run "nixos-generate-config --root '${NIXOS_ROOT_DIR}' --dir '${NIXOS_ROOT_DIR}/persist/etc/nixos/'"
  sanitize_hw_cfg

  run "install -d '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager'"
  run "cp -f '${NIXOS_CONFIG}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix'"
  run "cp -f '${NIXOS_HM_CONFIG}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/home.nix'"
  run "cp -rf '${NIXOS_HM_MODULES}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/modules'"

  run "install -d '${NIXOS_ROOT_DIR}/etc'"
  run "ln -sfn '/persist/etc/nixos' '${NIXOS_ROOT_DIR}/etc/nixos'"

  run "ln -sfn '/persist/etc/nixos/home-manager/home.nix' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/home.nix'"
  run "ln -sfn '/persist/etc/nixos/home-manager/modules' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/modules'"
  run "ln -sfn '/projects' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/Projects'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.bash_history'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.zsh_history'"

  if [ -d "${NIXOS_SCRIPTS_DIR}" ]; then
    run "cp -rf '${NIXOS_SCRIPTS_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/scripts'"
  fi
  if [ -d "${NIXOS_WALLPAPERS}" ]; then
    run "cp -rf '${NIXOS_WALLPAPERS}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers'"
  fi
  if [ -d "${NIXOS_ICONS}" ]; then
    run "cp -rf '${NIXOS_ICONS}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/icons'"
  fi
  if [ -d "${NIXOS_GTK_THEMES_DIR}" ]; then
    run "cp -rf '${NIXOS_GTK_THEMES_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/themes'"
  fi
  if [ -d "${NIXOS_GRUB_THEME_DIR}" ]; then
    run "cp -rf '${NIXOS_GRUB_THEME_DIR}' '${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme'"
  fi
}

seed_channels() {
  step "Seeding Nix channels"
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
  step "Adding initrd keyfile to LUKS"

  local key="${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d/cryptroot.key"

  run "install -d -m 0700 '${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d'"

  if [ -e "${key}" ]; then
    ok "Initrd keyfile already exists; leaving existing LUKS key slot unchanged"
    return
  fi

  run "dd if=/dev/urandom of='${key}' bs=64 count=1 status=none"
  run "chmod 0400 '${key}'"
  run "cryptsetup luksAddKey '${NIXOS_ROOT_PART}' '${key}'"
}

fix_persistent_home() {
  step "Ensuring ownership of persistent home"
  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- sh -lc \
    'mkdir -p /home/${NIXOS_USER} /persist/home/${NIXOS_USER}; \
     chown -R ${NIXOS_USER}:users /persist/home/${NIXOS_USER} /persist/etc/nixos/home-manager'"
}

install_system() {
  step "Building Slimbox NixOS system with classic nix-build"

  local config_path="${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix"
  local result_link="/tmp/slimbox-system"
  local system

  [ -f "${config_path}" ] || {
    warn "Staged NixOS configuration is missing: ${config_path}"
    exit 1
  }

  [ -e "${NIXOS_CHANNEL_PATH}/nixos/default.nix" ] || {
    warn "NixOS channel is not available at ${NIXOS_CHANNEL_PATH}"
    exit 1
  }

  [ -e "${NIXOS_HM_CHANNEL_PATH}" ] || {
    warn "Home Manager channel is not available at ${NIXOS_HM_CHANNEL_PATH}"
    exit 1
  }

  run "rm -f '${result_link}'"

  run "nix-build '${NIXOS_CHANNEL_PATH}/nixos' \
    -A system \
    -I 'nixpkgs=${NIXOS_CHANNEL_PATH}' \
    -I 'home-manager=${NIXOS_HM_CHANNEL_PATH}' \
    -I 'nixos-config=${config_path}' \
    -o '${result_link}'"

  system="$(readlink -f "${result_link}")"
  [ -n "${system}" ] && [ -e "${system}" ] || {
    warn "Failed to resolve built Slimbox NixOS system closure"
    exit 1
  }

  ok "Built Slimbox NixOS system: ${system}"

  step "Running nixos-install with the prebuilt system closure"
  run "nixos-install \
    --root '${NIXOS_ROOT_DIR}' \
    --system '${system}' \
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

set_user_password() {
  step "Setting password for user ${NIXOS_USER}"

  exec < /dev/tty
  while :; do
    read -rs -p "Enter new password for ${NIXOS_USER}: " PW1
    echo
    read -rs -p "Confirm password: " PW2
    echo
    if [[ "${PW1}" == "${PW2}" && -n "${PW1}" ]]; then
      break
    fi
    warn "Passwords did not match or were empty. Try again."
  done

  step "Applying password inside target"
  run "nixos-enter --root '${NIXOS_ROOT_DIR}' -- bash -lc 'echo ${NIXOS_USER}:\$(cat) | chpasswd'" <<<"${PW1}"

  unset PW1 PW2
  ok "Password set for ${NIXOS_USER}"
}

main() {
  preflight

  if [ "${RESUME_BUILD}" -eq 1 ]; then
    step "Resuming from NixOS system build; partitioning and formatting are left untouched"
    prepare_resume_mounts
    add_initrd_keyfile
    install_system
    fix_persistent_home
    seed_target_channels
    verify_uefi
    set_user_password
    ok "Installation complete."
    return
  fi

  reset_mounts
  wipe_disk
  partition_with_sfdisk
  setup_encryption_and_btrfs
  create_subvolumes
  mount_subvolumes
  generate_and_stage_configs
  seed_channels
  add_initrd_keyfile
  install_system
  fix_persistent_home
  seed_target_channels
  verify_uefi
  set_user_password

  ok "Installation complete."
}

main "$@"
