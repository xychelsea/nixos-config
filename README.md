# nix-darwin Configuration (greybox)

Personal multi-machine NixOS and nix-darwin configurations. Each git branch maps to one device (or platform). The `main` branch is a shared base / pseudo-device template for **NixOS** hosts; this branch is the macOS (nix-darwin) member of the fleet.

**License:** MIT License  
**Copyright:** © 2025–2026 Chelsea E. Manning

---

## Table of Contents

- [This machine](#this-machine)
- [Fleet / branches](#fleet--branches)
- [Darwin patterns (this host)](#darwin-patterns-this-host)
- [Shared Linux patterns (other hosts)](#shared-linux-patterns-other-hosts)
- [Repository structure](#repository-structure)
- [Configuration modules](#configuration-modules)
- [Installation / bootstrap](#installation--bootstrap)
- [Usage](#usage)
- [System information](#system-information)
- [Notes](#notes)

---

## This machine

| Field | Value |
|-------|-------|
| **Branch** | `greybox` |
| **Hostname** | (macOS / nix-darwin; not set like NixOS `networking.hostName`) |
| **Platform** | `aarch64-darwin` |
| **Role** | macOS workstation (nix-darwin) |
| **Status** | Active |

Notable configuration on this branch:

- nix-darwin system config with Home Manager (`<home-manager/nix-darwin>`)
- User home at `/Users/xychelsea`; HM entry imported from `/etc/nix-darwin/home-manager/home.nix`
- **Aerospace** tiling WM + **jankyborders** (not Hyprland / Wayland)
- Shell-focused HM modules: bash, zsh, git, starship, fastfetch, kitty
- `nixpkgs.config.allowUnfree = false`
- **No** LUKS, Btrfs impermanence, GRUB, SDDM, or Docker stack from the Linux templates

Checkout / config path on this Mac: **`/etc/nix-darwin`**.

---

## Fleet / branches

One branch per device. Checkout the branch that matches the machine, then rebuild.

| Branch | Hostname | Platform | Role | Notes |
|--------|----------|----------|------|-------|
| `main` | `default` | `x86_64-linux` | Base / pseudo-device | Shared NixOS template; `allowUnfree = false` |
| `silverbox` | `silverbox` | `x86_64-linux` | Desktop | Hyprland, Mullvad, Docker |
| `slimbox` | `slimbox` | `x86_64-linux` | Desktop + NVIDIA | Proprietary NVIDIA + container toolkit |
| `cloudbox` | `cloudbox` | `x86_64-linux` | Server | OpenSSH on port **36122** (key-only); kernel 6.12 |
| `jetson-agx-orin` | `llmbox` | `aarch64-linux` | Jetson Orin AGX | jetpack-nixos + CUDA; SSH **36122** |
| `reserver-industrial` | `mediabox` | `aarch64-linux` | Jetson Orin NX | `som = "orin-nx"`, `super = true`; SSH **36122** |
| `reserver-industrial-16gb` | `mediabox` | `aarch64-linux` | Jetson Orin NX (16 GB) | Same hostname; small deltas vs `reserver-industrial` |
| `raspi4` | `raspi4` | `aarch64-linux` | Raspberry Pi 4 | **Not successfully deployed; kept for future work** |
| `greybox` | (darwin) | `aarch64-darwin` | macOS (nix-darwin) | **This branch** — `/etc/nix-darwin`; Aerospace + jankyborders |

Do not run `nixos-rebuild` on this machine or `darwin-rebuild` on NixOS hosts.

---

## Darwin patterns (this host)

- System managed by **nix-darwin** (`configuration.nix` at repo root)
- Home Manager user `xychelsea` with `homeDirectory = "/Users/xychelsea"`
- Window management: Aerospace + jankyborders modules
- System packages include git, neovim, jq, eza, python3, kitty terminfo, home-manager
- `system.stateVersion = 6` (nix-darwin); HM `stateVersion = "26.05"`

---

## Shared Linux patterns (other hosts)

NixOS fleet members (not this Mac) typically use:

- Btrfs subvolumes `@`, `@nix`, `@persist` with **tmpfs `/home`**
- LUKS2 + Impermanence under `/persist`
- `hashedPasswordFile = "/persist/secrets/xychelsea.passwd"`
- Docker data-root on `/persist/var/lib/docker` where enabled

See any NixOS branch README for full Linux install details.

---

## Repository structure

Layout on this branch (`greybox`), checked out at `/etc/nix-darwin`:

```
/etc/nix-darwin/
├── configuration.nix          # nix-darwin system configuration
├── LICENSE
├── README.md
├── home-manager/
│   ├── home.nix               # Imports Aerospace, shells, kitty, etc.
│   └── modules/
├── grub-theme/                # Present in-tree (unused on Darwin)
├── themes/                    # GTK themes (legacy / unused on Darwin)
├── wallpapers/
├── scripts/
├── icons/
└── install.sh                 # NixOS-oriented; not used for Darwin bootstrap
```

### Key files

- **[configuration.nix](configuration.nix)** — nix-darwin system packages, fonts, HM wiring, `hostPlatform`
- **[home-manager/home.nix](home-manager/home.nix)** — Darwin user modules (Aerospace, jankyborders, shells)

---

## Configuration modules

Modules **imported on greybox** (`home-manager/home.nix`):

| Module | Description |
|--------|-------------|
| `aerospace.nix` | Aerospace tiling window manager |
| `bash.nix` | Bash |
| `fastfetch.nix` | Fastfetch |
| `git.nix` | Git |
| `jankyborders.nix` | Window borders |
| `kitty.nix` | Kitty terminal |
| `starship.nix` | Prompt |
| `zsh.nix` | Zsh |

Other modules may exist in-tree (Hyprland, Waybar, etc.) from the shared history but are **not** imported on this branch.

---

## Installation / bootstrap

1. Install Nix on macOS, then nix-darwin, following upstream nix-darwin docs.
2. Place this repository at `/etc/nix-darwin` on the `greybox` branch:

```bash
nix-shell -p git --run 'git clone -b greybox git@github.com:xychelsea/nixos-config /etc/nix-darwin'
```

(or update an existing checkout)

3. Rebuild:

```bash
sudo darwin-rebuild switch
```

Do **not** use `install.sh` on Darwin — it targets LUKS/Btrfs NixOS disks.

---

## Usage

### Ad-hoc tools with `nix-shell -p`

```bash
nix-shell -p git --run 'git status'
nix-shell -p git --run 'git checkout greybox'
nix-shell -p ripgrep --run 'rg hostPlatform configuration.nix'
```

### Switching branches

Only the `greybox` branch belongs on this Mac:

```bash
cd /etc/nix-darwin
nix-shell -p git --run 'git checkout greybox'
sudo darwin-rebuild switch
```

### Rebuilding

```bash
sudo darwin-rebuild switch
sudo darwin-rebuild switch --show-trace
```

Home Manager is applied through the nix-darwin module; a separate `home-manager switch` is unnecessary when using this layout.

Home Manager on these configs is often pinned via `fetchTarball` to `release-26.05` in `configuration.nix` — prefer that pin over an stale channel.

---

## System information

### Versions (this branch)

- **nix-darwin `system.stateVersion`:** 6
- **Home Manager `home.stateVersion`:** 26.05
- **Platform:** `aarch64-darwin`

### Services / UI (this machine)

- Aerospace + jankyborders (user HM)
- No SDDM/Hyprland/Mullvad/Docker from the Linux desktop template

---

## Notes

### Personal configuration

Username `xychelsea` and paths under `/Users/xychelsea` / `/etc/nix-darwin` are hardcoded. Adapt before reusing.

### Security

- Prefer SSH keys and macOS FileVault as appropriate for the Mac
- Linux fleet secrets (`/persist/secrets/…`) do not apply here

### Troubleshooting

- Rebuild: `sudo darwin-rebuild switch --show-trace`
- Missing CLIs: `nix-shell -p <pkg> --run '…'`

### References

- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Manual](https://nixos.org/manual/nixos/) (Linux fleet)

---

**Last Updated:** 2026
