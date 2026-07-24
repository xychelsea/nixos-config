# NixOS Configuration

Personal multi-machine NixOS and nix-darwin configurations. Each git branch maps to one device (or platform). The `main` branch is a shared base / pseudo-device template that other machines diverge from.

**License:** MIT License  
**Copyright:** © 2025–2026 Chelsea E. Manning

---

## Table of Contents

- [This machine](#this-machine)
- [Fleet / branches](#fleet--branches)
- [Shared Linux patterns](#shared-linux-patterns)
- [Repository structure](#repository-structure)
- [Configuration modules](#configuration-modules)
- [Installation](#installation)
- [Usage](#usage)
- [System information](#system-information)
- [Notes](#notes)

---

## This machine

| Field | Value |
|-------|-------|
| **Branch** | `slimbox` |
| **Hostname** | `slimbox` |
| **Platform** | `x86_64-linux` |
| **Role** | Desktop workstation |
| **Status** | Active |

Notable configuration on this branch:

- Hyprland + UWSM session via SDDM (Catppuccin)
- Proprietary NVIDIA drivers (`hardware.nvidia`, `services.xserver.videoDrivers = ["nvidia"]`)
- NVIDIA Container Toolkit for GPU-backed Docker workloads
- Mullvad VPN, Docker (data-root under `/persist`), rootless Docker enabled
- `nixpkgs.config.allowUnfree = true` (NVIDIA and proprietary apps)

Checkout path on this host: `/persist/etc/nixos`.

---

## Fleet / branches

One branch per device. Checkout the branch that matches the machine, then rebuild.

| Branch | Hostname | Platform | Role | Notes |
|--------|----------|----------|------|-------|
| `main` | `default` | `x86_64-linux` | Base / pseudo-device | Shared template; `allowUnfree = false` |
| `silverbox` | `silverbox` | `x86_64-linux` | Desktop | Hyprland, Mullvad, Docker |
| `slimbox` | `slimbox` | `x86_64-linux` | Desktop + NVIDIA | Proprietary NVIDIA + container toolkit |
| `cloudbox` | `cloudbox` | `x86_64-linux` | Server | OpenSSH on port **36122** (key-only); kernel 6.12 |
| `jetson-agx-orin` | `llmbox` | `aarch64-linux` | Jetson Orin AGX | jetpack-nixos + CUDA; SSH **36122** |
| `reserver-industrial` | `mediabox` | `aarch64-linux` | Jetson Orin NX | `som = "orin-nx"`, `super = true`; SSH **36122** |
| `reserver-industrial-16gb` | `mediabox` | `aarch64-linux` | Jetson Orin NX (16 GB) | Same hostname; small deltas vs `reserver-industrial` (e.g. rootless Docker, container toolkit) |
| `raspi4` | `raspi4` | `aarch64-linux` | Raspberry Pi 4 | **Not successfully deployed; kept for future work** |
| `greybox` | (darwin) | `aarch64-darwin` | macOS (nix-darwin) | Lives under `/etc/nix-darwin`; Aerospace + jankyborders |

`main` is the foundation other branches diverge from for hardware- and role-specific needs. Do not rebuild a machine from the wrong branch.

---

## Shared Linux patterns

These apply to NixOS hosts (not `greybox`):

### Filesystem: Btrfs + tmpfs home

- `@` — root (ephemeral with Impermanence)
- `@nix` — Nix store
- `@persist` — persistent data
- `/home` — **tmpfs** (not a Btrfs `@home` subvolume)

Subvolume mount options typically include `compress=zstd`, `noatime`, and `discard=async`.

### Disk encryption: LUKS2

Full-disk LUKS2 with a keyfile under `/persist/etc/cryptsetup-keys.d/` and initrd keyfile support for unlock after the first passphrase boot.

### Impermanence

Ephemeral root; only listed paths survive under `/persist`. Common persists include:

- System: `/etc/nixos`, `/etc/ssh`, `/etc/NetworkManager/system-connections`, `/etc/machine-id`, `/var/lib/docker`, `/projects`
- User (`xychelsea`): `.config`, `.local`, `.ssh`, `Documents`, `Downloads` (exact lists vary by branch)

### Auth

User `xychelsea` uses `hashedPasswordFile = "/persist/secrets/xychelsea.passwd"` (not a plaintext placeholder in `configuration.nix`).

### Docker

Docker is enabled on most NixOS branches with `data-root` on `/persist/var/lib/docker`. Rootless and NVIDIA toolkit settings differ by machine.

### Desktop stack (desktop branches)

Hyprland, Waybar, Rofi, Kitty, SDDM, PipeWire, Mullvad — on `main`, `silverbox`, `slimbox`, and the inactive `raspi4` template. Server/Jetson branches use a minimal Home Manager shell setup instead.

---

## Repository structure

Layout on this branch (`slimbox`):

```
/persist/etc/nixos/
├── configuration.nix          # NixOS system configuration
├── hardware-configuration.nix # Hardware-specific settings (machine-local; often gitignored)
├── install.sh                 # Automated LUKS/Btrfs desktop install script
├── LICENSE
├── README.md
├── home-manager/
│   ├── home.nix
│   └── modules/               # Per-app Home Manager modules
├── grub-theme/                # Custom GRUB theme
├── themes/                    # Catppuccin GTK themes
├── wallpapers/
├── scripts/                   # logout.sh, power.sh, Rofi config
└── icons/
```

Jetson branches also include `vendor/` (jetpack-nixos submodule) and `.gitmodules`.  
`greybox` is checked out at `/etc/nix-darwin` and does not use the LUKS/Btrfs layout above.

### Key files

- **[configuration.nix](configuration.nix)** — boot, filesystems, services, packages, networking
- **[home-manager/home.nix](home-manager/home.nix)** — Home Manager entry point and module imports
- **[install.sh](install.sh)** — partitioning, LUKS, Btrfs subvolumes, and NixOS install (desktop-oriented)

---

## Configuration modules

Home Manager modules present in-tree (imports vary by branch):

| Module | Description |
|--------|-------------|
| `bash.nix` | Bash shell |
| `cursor.nix` | Cursor theme (desktop) |
| `fastfetch.nix` | Fastfetch |
| `git.nix` | Git |
| `hyprland.nix` / `hyprland.lua` | Hyprland (desktop) |
| `hyprlock.nix` | Screen lock (desktop) |
| `hyprpaper.nix` | Wallpaper (desktop) |
| `kitty.nix` | Kitty terminal |
| `rofi.nix` | Launcher (desktop) |
| `signal-desktop.nix` | Signal (desktop) |
| `starship.nix` | Prompt |
| `waybar.nix` | Status bar (desktop) |
| `wlogout.nix` | Logout menu (desktop) |
| `xdg.nix` | XDG dirs / MIME (desktop) |
| `zsh.nix` | Zsh |
| `aerospace.nix` | Aerospace WM (**Darwin / greybox**) |
| `jankyborders.nix` | Window borders (**Darwin / greybox**) |

Desktop Linux branches may still carry `aerospace.nix` / `jankyborders.nix` on disk without importing them. Enable or disable modules via imports in `home-manager/home.nix`.

---

## Installation

### Desktop NixOS (`install.sh`)

Intended for LUKS + Btrfs machines (e.g. silverbox/slimbox-style installs).

**Warning:** The script destroys data on the target disk.

1. Boot NixOS installation media and clone this repo (checkout the correct device branch).
2. Review `configuration.nix` and `install.sh`:
   - `NIXOS_USER` (default `xychelsea`)
   - `NIXOS_HOST` (script default is still `silverbox` — set to match the branch)
   - Disk device (default `/dev/nvme0n1`)
3. Run:

```bash
sudo bash install.sh
# or
sudo bash install.sh --wipe
```

4. Set the LUKS passphrase and user password when prompted, then reboot.

**Note:** `install.sh` still pins NixOS/Home Manager channel URLs to **25.11**, while active configs use **stateVersion / Home Manager 26.05**. Align channels with the target system before relying on a fresh install.

### Jetson branches

- Initialize the jetpack submodule (`vendor/jetpack-nixos`) before building.
- Hostname may differ from the branch name (`llmbox`, `mediabox`).
- Prefer the documented Jetson/jetpack install path for that hardware; do not assume `install.sh` matches every SOM carrier board.

### Headless / SSH hosts (`cloudbox`, Jetsons)

OpenSSH listens on **36122** with password authentication disabled. Ensure firewall and keys are in place before locking yourself out.

### nix-darwin (`greybox`)

Configuration lives at `/etc/nix-darwin`. Use `darwin-rebuild` (not `nixos-rebuild`). See the `greybox` branch README “This machine” section when on that branch.

### Raspberry Pi (`raspi4`)

Inactive / incomplete. Uses `linuxPackages_rpi4`, extlinux, `/boot/firmware`, and nixos-hardware Pi 4 bits. Not a supported production install yet.

---

## Usage

### Ad-hoc tools with `nix-shell -p`

When a CLI tool is not on the current PATH, wrap it:

```bash
nix-shell -p git --run 'git status'
nix-shell -p git --run 'git checkout silverbox'
nix-shell -p ripgrep --run 'rg hostName configuration.nix'
nix-shell -p jq --run 'jq . some.json'
```

### Switching branches

```bash
cd /persist/etc/nixos   # or /etc/nix-darwin on greybox
nix-shell -p git --run 'git checkout <branch-name>'
sudo nixos-rebuild switch   # NixOS hosts
# darwin-rebuild switch     # greybox only
```

Only check out the branch that belongs to this hardware.

### Rebuilding NixOS

```bash
sudo nixos-rebuild switch
sudo nixos-rebuild test
sudo nixos-rebuild boot
```

Debug failures with:

```bash
sudo nixos-rebuild switch --show-trace
```

### Home Manager

Most hosts pull Home Manager through the system configuration (`home-manager` NixOS/darwin module). After editing modules:

```bash
sudo nixos-rebuild switch
```

Standalone `home-manager switch` is only needed if you use a separate HM channel workflow.

### Updating channels

```bash
sudo nix-channel --update nixos
sudo nixos-rebuild switch --upgrade
```

Home Manager on these configs is often pinned via `fetchTarball` to `release-26.05` in `configuration.nix` — prefer that pin over an stale channel.

---

## System information

### Versions (this branch)

- **NixOS / HM stateVersion:** 26.05
- **Home Manager tarball:** `release-26.05`
- **`install.sh` channel URLs:** still 25.11 (see Installation note)

### Architecture

- This machine: `x86_64-linux`
- Fleet also includes `aarch64-linux` (Jetson, Pi) and `aarch64-darwin` (`greybox`)

### Services (this machine)

- NetworkManager, Mullvad VPN, PipeWire, SDDM, Docker, Btrfs scrub (as configured)
- NVIDIA driver stack + nvidia-container-toolkit

### Boot (this machine)

- GRUB (EFI) with custom theme under `grub-theme/`
- LUKS2 + Btrfs subvolumes
- `linuxPackages_latest`


---

## Notes

### Personal configuration

Username `xychelsea` is hardcoded in `configuration.nix`, Home Manager, and `install.sh`. Adapt paths and user names before reusing this elsewhere.

Regenerate hardware config on new machines:

```bash
sudo nixos-generate-config
```

### Security

- Use a strong LUKS passphrase on first unlock
- Keep `/persist/secrets/xychelsea.passwd` and LUKS keyfiles permission-restricted
- Place SSH keys under the persisted `.ssh` directory
- On SSH hosts, confirm key-only auth on port 36122 before disabling other access

### Troubleshooting

- Boot / encryption: GRUB, UEFI entries, keyfile path under `/persist/etc/cryptsetup-keys.d/`
- Rebuild: `sudo nixos-rebuild switch --show-trace`
- Missing CLIs in a minimal environment: `nix-shell -p <pkg> --run '…'`

### References

- [NixOS Manual](https://nixos.org/manual/nixos/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)

---

**Last Updated:** 2026
