#!/usr/bin/env bash
set -euo pipefail

NIXOS_DISK=${NIXOS_DISK:-/dev/sda}
NIXOS_USER=xychelsea #${NIXOS_USER:-user}
NIXOS_HOST=raspi4 #${NIXOS_HOST:-nixos}

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

NIXOS_CHANNEL_URL=https://nixos.org/channels/nixos-25.05
NIXOS_HW_CHANNEL_URL=https://github.com/NixOS/nixos-hardware/archive/master.tar.gz
NIXOS_HM_CHANNEL_URL=https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz

NIXOS_CRYPT_NAME=nixos
NIXOS_CRYPT_PART=/dev/mapper/${NIXOS_CRYPT_NAME}

DD_WIPE=0
if [[ "${1:-}" == "--wipe" ]]; then
  DD_WIPE=1
  shift
fi

declare -A SUBVOL_TO_MOUNTPOINT=(
  ["@"]="/"
  ["@nix"]="/nix"
  ["@home"]="/home"
  ["@persist"]="/persist"
)

declare -A SUBVOL_OPTS=(
  ["@"]="${NIXOS_PART_OPTS}"
  ["@nix"]="${NIXOS_PART_OPTS}"
  ["@home"]="${NIXOS_PART_OPTS}"
  ["@persist"]="${NIXOS_PART_OPTS}"
)

declare -A FS_DEV=(
  ["/boot/efi"]="/dev/disk/by-label/EFI"
  ["/"]="/dev/disk/by-label/nixos"
  ["/nix"]="/dev/disk/by-label/nixos"
  ["/home"]="/dev/disk/by-label/nixos"
  ["/persist"]="/dev/disk/by-label/nixos"
)

SUBVOL_ORDER=( "@" "@nix" "@home" "@persist" )

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
  command -v cryptsetup >/dev/null || { warn "cryptsetup is required"; exit 1; }

  ok "Using disk ${NIXOS_DISK}"
}

show_holders() {
  step "Inspecting holders on ${NIXOS_DISK}"
  run "lsblk -e7 -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS,PKNAME ${NIXOS_DISK} ${NIXOS_DISK}p* || true"
  run "findmnt -rn -S '^${NIXOS_DISK}(|p[0-9]+)$' -o SOURCE,TARGET || true"
  run "swapon --show || true"
  command -v dmsetup >/dev/null && run "dmsetup ls --tree || true"
}

release_disk_holders() {
  step "Releasing all holders of ${NIXOS_DISK}"
  while read -r tgt; do
    run "umount -R '${tgt}' || true"
  done < <(findmnt -rn -S "^${NIXOS_DISK}(|p[0-9]+)$" -o TARGET)
  while read -r dev; do
    run "swapoff '${dev}' || true"
  done < <(awk -v d="${NIXOS_DISK}" '$1 ~ "^"d {print $1}' /proc/swaps 2>/dev/null || true)
  if command -v cryptsetup >/dev/null; then
    while read -r map; do
      if lsblk -no PKNAME "${map}" 2>/dev/null | grep -q "$(basename "${NIXOS_DISK}")"; then
        run "cryptsetup luksClose '$(basename "${map}")' || true"
      fi
    done < <(lsblk -lnpo NAME,TYPE | awk '$2=="crypt"{print $1}')
  fi
  if command -v pvs >/dev/null; then
    run "pvscan --cache || true"
    while read -r vg; do
      [ -n "${vg}" ] && run "vgchange -an '${vg}' || true"
    done < <(pvs --noheadings -o vg_name,pv_name 2>/dev/null | awk -v d="${NIXOS_DISK}" '$2 ~ "^"d {print $1}' | sort -u)
  fi
  if command -v mdadm >/dev/null; then
    while read -r md; do
      run "mdadm --stop '${md}' || true"
    done < <(cat /proc/mdstat 2>/dev/null | awk '/^md[0-9]+/ {print "/dev/"$1}')
  fi
  run "sync"
  run "udevadm settle || true"
  run "blockdev --rereadpt '${NIXOS_DISK}' || true"
  run "partprobe '${NIXOS_DISK}' || true"
  run "udevadm settle || true"
}

reset_mounts() {
  step "Resetting any existing mounts and LUKS mappings"
  run "cryptsetup luksClose ${NIXOS_CRYPT_NAME} 2>/dev/null || true"
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

  run "install -d ${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d"
  run "install -d ${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager"
  run "install -d ${NIXOS_ROOT_DIR}/persist/var/lib/nixos"
  run "install -d ${NIXOS_ROOT_DIR}/persist/projects"
}

partition_with_sfdisk() {
  step "Ensuring disk is idle before partitioning"
  release_disk_holders
  show_holders
  step "Partitioning with sfdisk"
  sfdisk --wipe always --wipe-partitions always "${NIXOS_DISK}" <<EOF
label: gpt
,512MiB,uefi,*
,,linux
EOF
  run "sgdisk --change-name=1:ESP --change-name=2:${NIXOS_CRYPT_NAME} --typecode=2:8309 '${NIXOS_DISK}' || true"

  run "partprobe '${NIXOS_DISK}'"
  local PARTSEP=""; [[ "${NIXOS_DISK}" =~ (nvme|mmcblk|loop) ]] && PARTSEP="p"
  NIXOS_BOOT_PART="${NIXOS_DISK}${PARTSEP}1"
  NIXOS_ROOT_PART="${NIXOS_DISK}${PARTSEP}2"

  run "mkfs.fat -F32 -n FIRMWARE ${NIXOS_BOOT_PART}"
}

setup_encryption_and_btrfs() {
  step "Creating LUKS2 container and Btrfs filesystem"
  if ! cryptsetup isLuks "${NIXOS_ROOT_PART}"; then
    run "cryptsetup luksFormat --type luks2 --cipher aes-cbc-essiv:sha256 --key-size 256 --batch-mode --pbkdf pbkdf2 '${NIXOS_ROOT_PART}'"
  fi
  if [ ! -e "${NIXOS_CRYPT_PART}" ]; then
    run "cryptsetup open '${NIXOS_ROOT_PART}' '${NIXOS_CRYPT_NAME}'"
  fi
  if ! blkid -s TYPE -o value "${NIXOS_CRYPT_PART}" | grep -q '^btrfs$'; then
    run "mkfs.btrfs -f -L nixos '${NIXOS_CRYPT_PART}'"
  fi
}

patch_hw_cfg() {
  local f="${NIXOS_ROOT_DIR}/persist/etc/nixos/hardware-configuration.nix"
  local args=()
  for mp in "${!FS_DEV[@]}"; do
    local mp_esc
    mp_esc=$(printf '%s' "$mp" | sed 's/[\/&]/\\&/g')
    args+=( -e "/fileSystems\\.\"${mp_esc}\"/,/}/ { s#device = [^;]*;#device = \"${FS_DEV[$mp]}\";# }" )
  done
  args+=( -e "/fileSystems\\.\"\\/persist\"/,/}/ {
              /neededForBoot/! s/^([[:space:]]*)}/\1  neededForBoot = true;\n\1}/
            }" )
  sed -i -E "${args[@]}" "$f"
}

generate_and_stage_configs() {
  step "Generating NixOS hardware config and staging your files"
  if [ ! -f "${PWD}/hardware-configuration.nix" ]; then
    run "nixos-generate-config --root ${NIXOS_ROOT_DIR} --dir ${NIXOS_ROOT_DIR}/persist/etc/nixos/"
    patch_hw_cfg
  fi

  run "install -d ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager"
  run "cp -rf ${NIXOS_CONFIG} ${NIXOS_ROOT_DIR}/persist/etc/nixos/configuration.nix"
  run "cp -rf ${NIXOS_HM_CONFIG} ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/home.nix"
  run "cp -rf ${NIXOS_HM_MODULES} ${NIXOS_ROOT_DIR}/persist/etc/nixos/home-manager/modules"
  run "install -d ${NIXOS_ROOT_DIR}/etc"
  run "ln -sfn '${NIXOS_ROOT_DIR}/persist/etc/nixos' '${NIXOS_ROOT_DIR}/etc/nixos'"

  run "ln -sf '/persist/etc/nixos/home-manager/home.nix' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/home.nix'"
  run "ln -sf '/persist/etc/nixos/home-manager/modules' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.config/home-manager/modules'"

  run "ln -sfn '/projects' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/Projects'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.bash_history'"
  run "ln -sfn '/dev/null' '${NIXOS_ROOT_DIR}/persist/home/${NIXOS_USER}/.zsh_history'"

  if [ -d "${NIXOS_SCRIPTS_DIR}" ]; then run "cp -rf ${NIXOS_SCRIPTS_DIR} ${NIXOS_ROOT_DIR}/persist/etc/nixos/scripts"; fi
  if [ -d "${NIXOS_WALLPAPERS}" ]; then run "cp -rf ${NIXOS_WALLPAPERS} ${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers"; fi
  if [ -d "${NIXOS_ICONS}" ]; then run "cp -rf ${NIXOS_ICONS} ${NIXOS_ROOT_DIR}/persist/etc/nixos/icons"; fi
  if [ -d "${NIXOS_GTK_THEMES_DIR}" ]; then run "cp -rf ${NIXOS_ICONS} ${NIXOS_ROOT_DIR}/persist/etc/nixos/themes"; fi
  if [ -d "${NIXOS_GRUB_THEME_DIR}" ]; then run "cp -rf ${NIXOS_GRUB_THEME_DIR} ${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme"; fi


  run "cp -rf ${NIXOS_DIR}/grub-theme ${NIXOS_ROOT_DIR}/persist/etc/nixos/grub-theme"
  run "cp -rf ${NIXOS_DIR}/scripts ${NIXOS_ROOT_DIR}/persist/etc/nixos/wallpapers"
}

seed_channels() {
  step "Seeding Nix channels"
  run "nix-channel --add ${NIXOS_CHANNEL_URL} nixos"
  run "nix-channel --add ${NIXOS_HW_CHANNEL_URL} nixos-hardware"
  run "nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager"
  run "nix-channel --update"
}

seed_target_channels() {
  step "Seeding Nix and Home-Manager channels inside the target"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc \
    'nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
     nix-channel --add ${NIXOS_HW_CHANNEL_URL} nixos-hardware; \
     nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
     nix-channel --update'"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc \
    'id ${NIXOS_USER} >/dev/null 2>&1 && \
     su - ${NIXOS_USER} -c \
       \"nix-channel --add ${NIXOS_CHANNEL_URL} nixos; \
        nix-channel --add ${NIXOS_HW_CHANNEL_URL} nixos-hardware; \
        nix-channel --add ${NIXOS_HM_CHANNEL_URL} home-manager; \
        nix-channel --update\" || true'"
}

fix_persistent_home() {
  step "Ensuring ownership of persistent home"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc 'mkdir -p /home/${NIXOS_USER} /persist/home/${NIXOS_USER}; chown -R ${NIXOS_USER}:users /persist/home/${NIXOS_USER} /persist/etc/nixos/home-manager'"
}

install_system() {
  step "Running nixos-install"
  run "nixos-install --root ${NIXOS_ROOT_DIR}"

  nixos-enter --root ${NIXOS_ROOT_DIR} -- sh -lc \
    'nix-channel --add https://nixos.org/channels/nixos-25.05 nixos; \
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager; \
    nix-channel --update'
}

add_initrd_keyfile() {
  step "Adding initrd keyfile to LUKS"
  run "dd if=/dev/urandom of=${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d/cryptroot.key bs=64 count=1"
  run "chmod 0700 ${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d"
  run "chmod 0400 ${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d/cryptroot.key"
  run "cryptsetup luksAddKey ${NIXOS_ROOT_PART} ${NIXOS_ROOT_DIR}/persist/etc/cryptsetup-keys.d/cryptroot.key"
}

verify_uefi() {
  step "Verifying UEFI boot entry"
  test -d /sys/firmware/efi || { warn "Not booted in UEFI"; return 0; }
  run "mountpoint -q /sys/firmware/efi/efivars || mount -t efivarfs efivarfs /sys/firmware/efi/efivars"
  run "nixos-enter --root ${NIXOS_ROOT_DIR} -- nix-shell -p efibootmgr --run 'efibootmgr -v'"
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
  set_user_password
  ok "Installation complete."
}

main "$@"

