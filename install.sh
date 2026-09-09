#!/usr/bin/env bash
set -euo pipefail

NIXOS_DISK=${NIXOS_DISK:-/dev/nvme0n1}
NIXOS_USER=xychelsea #${NIXOS_USER:-user}
NIXOS_HOST=silverbox #${NIXOS_HOST:-nixos}

# Raspberry Pi firmware boot partition. This is not a UEFI-mounted /boot/efi.
NIXOS_BOOT_DIR=/boot/firmware
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
NIXOS_RPI_REPO=https://github.com/nvmd/nixos-raspberrypi.git
NIXOS_RPI_REV=v1.20260801.0
NIXOS_RPI_SRC=${NIXOS_RPI_SRC:-/tmp/nixos-raspberrypi-${NIXOS_RPI_REV}}

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
      printf "Unknown argument: %s\n" "$1" >&2
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

declare -A FS_DEV=(
  ["/boot/firmware"]="/dev/disk/by-label/FIRMWARE"
  ["/"]="/dev/disk/by-label/nixos"
  ["/nix"]="/dev/disk/by-label/nixos"
  ["/persist"]="/dev/disk/by-label/nixos"
)

SUBVOL_ORDER=( "@" "@nix" "@persist" )
RED=$'\e[31m'; GRN=$'\e[32m'; BLU=$'\e[34m'; DIM=$'\e[2m'; RST=$'\e[0m'
step(){ printf "\n${BLU}==>${RST} %s\n" "$*"; }
ok(){ printf "${GRN}✔${RST} %s\n" "$*"; }
warn(){ printf "${RED}✖${RST} %s\n" "$*"; }
run(){ printf "${DIM}$ %s${RST}\n" "$*"; eval "$@"; }

preflight() {
  step "Preinstall checks."
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then warn "Run as root"; exit 1; fi
  local PARTSEP=""
  [[ "${NIXOS_DISK}" =~ (nvme|mmcblk|loop) ]] && PARTSEP="p"
  NIXOS_BOOT_PART="${NIXOS_DISK}${PARTSEP}1"
  NIXOS_ROOT_PART="${NIXOS_DISK}${PARTSEP}2"

  [ -b "${NIXOS_DISK}" ] || { warn "Not a block device: ${NIXOS_DISK}"; exit 1; }
  [ -f "${NIXOS_CONFIG}" ] || { warn "Missing ${NIXOS_CONFIG}"; exit 1; }
  [ -f "${NIXOS_HM_CONFIG}" ] || { warn "Missing ${NIXOS_HM_CONFIG}"; exit 1; }

  local required=(
    btrfs
    mkfs.btrfs
    mkfs.fat
    sfdisk
    sgdisk
    wipefs
    partprobe
    udevadm
    nixos-generate-config
    nixos-install
    nixos-enter
    nix-build
    git
  )
  local cmd
  for cmd in "${required[@]}"; do
    command -v "${cmd}" >/dev/null || { warn "${cmd} is required"; exit 1; }
  done

  ok "Using disk ${NIXOS_DISK}"
}

show_holders() {
  step "Inspecting holders on ${NIXOS_DISK}"
  run "lsblk -e7 -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS,PKNAME ${NIXOS_DISK} ${NIXOS_DISK}p* || true"
  run "findmnt -rn -S '^${NIXOS_DISK}(|p[0-9]+)$' -o SOURCE,TARGET || true"
  run "swapon --show || true"
}

release_disk_holders() {
  step "Releasing all holders of ${NIXOS_DISK}"
  while read -r tgt; do
    [ -n "${tgt}" ] && run "umount -R '${tgt}' || true"
  done < <(findmnt -rn -S "^${NIXOS_DISK}(|p[0-9]+)$" -o TARGET || true)

  while read -r dev; do
    [ -n "${dev}" ] && run "swapoff '${dev}' || true"
  done < <(awk -v d="${NIXOS_DISK}" '$1 ~ "^"d {print $1}' /proc/swaps 2>/dev/null || true)

  if command -v pvs >/dev/null; then
    run "pvscan --cache || true"
    while read -r vg; do
      [ -n "${vg}" ] && run "vgchange -an '${vg}' || true"
    done < <(pvs --noheadings -o vg_name,pv_name 2>/dev/null | awk -v d="${NIXOS_DISK}" '$2 ~ "^"d {print $1}' | sort -u)
  fi

  if command -v mdadm >/dev/null; then
    while read -r md; do
      [ -n "${md}" ] && run "mdadm --stop '${md}' || true"
    done < <(cat /proc/mdstat 2>/dev/null | awk '/^md[0-9]+/ {print "/dev/"$1}')
  fi

  run "sync"
  run "udevadm settle || true"
  run "blockdev --rereadpt '${NIXOS_DISK}' || true"
  run "partprobe '${NIXOS_DISK}' || true"
  run "udevadm settle || true"
}

reset_mounts() {
  step "Resetting any existing mounts"
  run "umount ${NIXOS_ROOT_PART} 2>/dev/null || true"
  run "umount ${NIXOS_BOOT_PART} 2>/dev/null || true"
  run "umount -R ${NIXOS_ROOT_DIR} 2>/dev/null || true"
  run "mkdir -p ${NIXOS_ROOT_DIR} 2>/dev/null || true"
}

wipe_disk() {
  step "Preparing disk for wipe"
  release_disk_holders
  show_holders
  step "Wiping partition tables and signatures"
  run "sgdisk --zap-all ${NIXOS_DISK}"
  run "wipefs -af ${NIXOS_DISK}"
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
,1GiB,uefi
,,linux
EOF_PARTITIONS

  # The first partition is the Raspberry Pi firmware FAT filesystem.
  # It uses the conventional ESP GPT type, but we boot through Raspberry Pi
  # firmware rather than UEFI/systemd-boot.
  run "sgdisk --change-name=1:FIRMWARE --typecode=1:EF00 --change-name=2:nixos --typecode=2:8300 '${NIXOS_DISK}'"
  run "partprobe '${NIXOS_DISK}'"
  run "udevadm settle"

  local PARTSEP=""
  [[ "${NIXOS_DISK}" =~ (nvme|mmcblk|loop) ]] && PARTSEP="p"
  NIXOS_BOOT_PART="${NIXOS_DISK}${PARTSEP}1"
  NIXOS_ROOT_PART="${NIXOS_DISK}${PARTSEP}2"

  run "mkfs.fat -F32 -n FIRMWARE '${NIXOS_BOOT_PART}'"
}

setup_btrfs() {
  step "Creating unencrypted Btrfs filesystem"
  run "mkfs.btrfs -f -L nixos '${NIXOS_ROOT_PART}'"
}

create_subvolumes() {
  step "Creating Btrfs subvolumes from manifest"
  run "mount -o subvolid=5 '${NIXOS_ROOT_PART}' '${NIXOS_ROOT_DIR}'"
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
  run "mount -o subvol=@,${root_opts} '${NIXOS_ROOT_PART}' '${NIXOS_ROOT_DIR}'"

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
    run "mount -o subvol=${sv},${opts} '${NIXOS_ROOT_PART}' '${NIXOS_ROOT_DIR}${mp}'"
  done

  run "install -d ${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager"
  run "install -d ${NIXOS_ROOT_DIR}/persist/projects"
  run "install -d ${NIXOS_ROOT_DIR}/persist/var/lib/nixos"
}

sanitize_hw_cfg() {
  local f="${NIXOS_ROOT_DIR}/persist/etc/nixos/hardware-configuration.nix"
  local tmp="${f}.tmp"

  [ -f "${f}" ] || { warn "Missing generated hardware configuration: ${f}"; exit 1; }

  # configuration.nix is the authority for the filesystem topology.  In
  # particular, this host intentionally defines / and /home as tmpfs while
  # /nix and /persist live on Btrfs.  nixos-generate-config observes the
  # installer's temporary /mnt mounts and would otherwise add competing
  # fileSystems declarations (for example, / as Btrfs), causing module
  # evaluation conflicts.
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
  step "Generating NixOS hardware config and staging your files"
  run "install -d ${NIXOS_ROOT_DIR}/persist/etc/nixos"
  run "nixos-generate-config --root ${NIXOS_ROOT_DIR} --dir ${NIXOS_ROOT_DIR}/persist/etc/nixos/"
  sanitize_hw_cfg
  run "install -d ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager"
  run "cp -rf ${NIXOS_CONFIG} ${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix"
  run "cp -rf ${NIXOS_HM_CONFIG} ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/home.nix"
  run "cp -rf ${NIXOS_HM_MODULES} ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/modules"
  run "install -d ${NIXOS_ROOT_DIR}/etc"
  run "ln -sfn '/persist/etc/nixos' '${NIXOS_ROOT_DIR}/etc/nixos'"
  run "ln -sf '/persist/etc/nixos/home-manager/home.nix' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/home.nix'"
  run "ln -sf '/persist/etc/nixos/home-manager/modules' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/modules'"
  run "ln -sfn '/projects' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/Projects'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.bash_history'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.zsh_history'"
  if [ -d "${NIXOS_SCRIPTS_DIR}" ]; then run "cp -rf ${NIXOS_SCRIPTS_DIR} ${NIXOS_ROOT_DIR}/persist/etc/nixos/scripts"; fi
  if [ -d "${NIXOS_WALLPAPERS}" ]; then run "cp -rf ${NIXOS_WALLPAPERS} ${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers"; fi
  if [ -d "${NIXOS_ICONS}" ]; then run "cp -rf ${NIXOS_ICONS} ${NIXOS_ROOT_DIR}/persist/etc/nixos/icons"; fi
  if [ -d "${NIXOS_GTK_THEMES_DIR}" ]; then run "cp -rf ${NIXOS_GTK_THEMES_DIR} ${NIXOS_ROOT_DIR}/persist/etc/nixos/themes"; fi
  if [ -d "${NIXOS_GRUB_THEME_DIR}" ]; then run "cp -rf ${NIXOS_GRUB_THEME_DIR} ${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme"; fi
}

seed_channels() {
  step "Seeding Nix channels"
  run "nix-channel --add ${NIXOS_CHANNEL_URL} nixos"
  run "nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager"
  run "nix-channel --update"
}

seed_target_channels() {
  step "Seeding Nix and Home-Manager channels inside the target"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc \
    'nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
     nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
     nix-channel --update'"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc \
    'id ${NIXOS_USER} >/dev/null 2>&1 && \
     su - ${NIXOS_USER} -c \
       \"nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
        nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
        nix-channel --update\" || true'"
}

fix_persistent_home() {
  step "Ensuring ownership of persistent home"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc 'mkdir -p /home/${NIXOS_USER} /persist/home/${NIXOS_USER}; chown -R ${NIXOS_USER}:users /persist/home/${NIXOS_USER} /persist/etc/nixos/home-manager'"
}

install_system() {
  step "Preparing Raspberry Pi 5 NixOS module set"

  local config_path="${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix"
  local result_link="/tmp/raspi5-system"
  local eval_expr="/tmp/raspi5-system.nix"
  local system

  [ -f "${config_path}" ] || {
    warn "Staged NixOS configuration is missing: ${config_path}"
    exit 1
  }

  # Keep the install entirely on the classic Nix interface, but evaluate the
  # target through nixos-raspberrypi so that the Pi 5 vendor kernel, firmware,
  # bootloader modules, and the 16 KiB jemalloc compatibility overlay are part
  # of the target system.  The source is pinned to the same release family as
  # the installer rather than following the upstream development branch.
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

          # configuration.nix still contains x86/cloudbox-era boot settings.
          # Keep those overrides local to the installer until the repository
          # configuration itself is cleaned up.
          boot.kernelPackages = lib.mkForce
            nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi5;

          # rustup 1.29.0 reaches a successful cargo build on aarch64 here,
          # then fails only in cargoCheckHook. Keep rustup in the target while
          # disabling that package check for this Pi-specific installation.
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

          # The repository currently defines an EFI /boot mount.  Disable it
          # and expose the FAT partition where the Raspberry Pi bootloader
          # module expects firmware and generations.
          fileSystems."/boot".enable = lib.mkForce false;
          fileSystems."/boot/firmware" = {
            device = "/dev/disk/by-label/FIRMWARE";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
          };

          # This Pi installation has only Btrfs storage.  Do not pull ZFS and
          # its out-of-tree kernel module into the Raspberry Pi kernel build.
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
  run "rm -f '${result_link}'"
  run "nix-build '${eval_expr}' \\
    --argstr rpiSrc '${NIXOS_RPI_SRC}' \\
    --argstr configPath '${config_path}' \\
    --option extra-substituters 'https://nixos-raspberrypi.cachix.org' \\
    --option extra-trusted-public-keys 'nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=' \\
    -o '${result_link}'"

  system="$(readlink -f "${result_link}")"
  [ -n "${system}" ] && [ -e "${system}" ] || {
    warn "Failed to resolve built Raspberry Pi 5 NixOS system closure"
    exit 1
  }

  ok "Built Raspberry Pi 5 NixOS system: ${system}"

  step "Running nixos-install with the prebuilt Raspberry Pi system closure"
  run "nixos-install \\
    --root '${NIXOS_ROOT_DIR}' \\
    --system '${system}' \\
    --no-channel-copy \\
    --no-root-passwd"
}

verify_firmware_partition() {
  step "Verifying Raspberry Pi firmware partition"
  run "mountpoint -q '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "findmnt '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}'"
  run "blkid '${NIXOS_BOOT_PART}'"
  run "find '${NIXOS_ROOT_DIR}${NIXOS_BOOT_DIR}' -maxdepth 2 -type f -printf '%P\n' | sort | head -100"
}

set_user_password() {
  step "Setting password for user ${NIXOS_USER}"
  exec < /dev/tty
  while : ; do
    read -rs -p "Enter new password for ${NIXOS_USER}: " PW1; echo
    read -rs -p "Confirm password: " PW2; echo
    if [[ "$PW1" == "$PW2" && -n "$PW1" ]]; then break; fi
    warn "Passwords did not match or were empty. Try again."
  done
  step "Applying password inside target"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- bash -lc 'echo ${NIXOS_USER}:\$(cat) | chpasswd'" <<<"$PW1"
  unset PW1 PW2
  ok "Password set for ${NIXOS_USER}"
}

main() {
  preflight

  if [ "${RESUME_BUILD}" -eq 1 ]; then
    step "Resuming from NixOS system build; disk layout and staged configuration are left untouched"
    install_system
    fix_persistent_home
    seed_target_channels
    verify_firmware_partition
    set_user_password
    ok "Installation complete."
    return
  fi

  reset_mounts
  wipe_disk
  partition_with_sfdisk
  setup_btrfs
  create_subvolumes
  mount_subvolumes
  generate_and_stage_configs
  seed_channels
  install_system
  fix_persistent_home
  seed_target_channels
  verify_firmware_partition
  set_user_password
  ok "Installation complete."
}

main "$@"
