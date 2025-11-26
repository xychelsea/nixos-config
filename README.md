# NixOS Configuration

A comprehensive NixOS system configuration repository featuring a modular setup with Btrfs subvolumes, LUKS encryption, Impermanence, and Hyprland window manager.

**License:** MIT License  
**Copyright:** © 2025 Chelsea E. Manning

---

## Table of Contents

- [Introduction](#introduction)
- [Repository Structure](#repository-structure)
- [Branches](#branches)
- [Key Features](#key-features)
- [Configuration Modules](#configuration-modules)
- [Installation](#installation)
- [Usage](#usage)
- [System Information](#system-information)
- [Notes](#notes)

---

## Introduction

This repository contains a complete NixOS system configuration designed for personal use. It provides a reproducible, declarative system setup with modern features including:

- **Declarative Configuration**: Entire system defined in Nix expressions
- **Modular Architecture**: Home Manager modules for easy customization
- **Security**: Full disk encryption with LUKS2
- **Modern Desktop**: Hyprland window manager with Wayland
- **Ephemeral Root**: Impermanence for a clean system state
- **Automated Installation**: Script-based setup process

**Target Audience**: This configuration is intended for personal use and may require modification for your specific hardware and preferences. The username `xychelsea` is hardcoded in several places and should be changed if adapting this configuration.

---

## Repository Structure

```
/persist/etc/nixos/
├── configuration.nix          # Main NixOS system configuration
├── hardware-configuration.nix # Hardware-specific settings (auto-generated)
├── install.sh                 # Automated installation script
├── LICENSE                    # MIT License
│
├── home-manager/              # Home Manager user configuration
│   ├── home.nix               # Main Home Manager entry point
│   └── modules/               # Modular application configurations
│       ├── bash.nix           # Bash shell configuration
│       ├── cursor.nix         # Cursor theme settings
│       ├── fastfetch.nix      # System information tool
│       ├── hyprland.nix       # Hyprland window manager
│       ├── hyprlock.nix       # Screen lock configuration
│       ├── hyprpaper.nix      # Wallpaper manager
│       ├── kitty.nix          # Terminal emulator
│       ├── neovim.nix         # Text editor
│       ├── rofi.nix           # Application launcher
│       ├── signal-desktop.nix # Signal messaging app
│       ├── starship.nix       # Shell prompt
│       ├── waybar.nix         # Status bar
│       ├── wlogout.nix        # Logout menu
│       └── xdg.nix            # XDG configuration
│
├── grub-theme/                # Custom GRUB bootloader theme
│   ├── theme.txt              # GRUB theme configuration
│   ├── background.png         # Boot screen background
│   ├── logo.png               # Boot screen logo
│   ├── font.pf2               # GRUB font
│   └── icons/                 # OS detection icons
│
├── themes/                    # GTK themes
│   ├── Catppuccin-Dark/       # Dark theme variant
│   ├── Catppuccin-Light/      # Light theme variant
│   └── [hdpi/xhdpi variants]  # High DPI variants
│
├── wallpapers/                # Desktop wallpapers
│   ├── apple-black-4k.png
│   ├── arch-black-4k.png
│   ├── nix-black-4k.png
│   └── ubuntu-black-4k.png
│
├── scripts/                   # Utility scripts
│   ├── logout.sh              # Logout menu launcher
│   ├── power.sh               # Power management
│   └── config.rasi            # Rofi configuration
│
└── icons/                     # Custom icons
    ├── hibernate.png
    ├── lock.png
    ├── logout.png
    ├── reboot.png
    ├── shutdown.png
    └── suspend.png
```

### Key Files

- **[configuration.nix](configuration.nix)**: Main system configuration defining boot, filesystems, services, packages, and system-wide settings
- **[home-manager/home.nix](home-manager/home.nix)**: Home Manager entry point that imports all user configuration modules
- **[install.sh](install.sh)**: Automated installation script that handles partitioning, encryption, filesystem setup, and system installation
- **[home-manager/modules/](home-manager/modules/)**: Directory containing modular application configurations for easy customization

---

## Branches

This repository maintains multiple branches for different hardware configurations:

### `main`
The base/default configuration branch. Contains the core system configuration that serves as the foundation for other branches.

### `raspi4`
Raspberry Pi 4 specific configuration. Includes ARM-specific settings, U-Boot configuration, and firmware directory adjustments for Raspberry Pi hardware.

### `silverbox`
Configuration tailored for the "silverbox" machine. Contains hardware-specific settings and may include device-specific packages or configurations.

### `slimbox`
Configuration for the "slimbox" machine. Similar to silverbox but customized for different hardware specifications.

**Note**: All branches share a common base configuration from `main` but diverge for hardware-specific requirements. When switching branches, ensure you're using the appropriate configuration for your hardware.

---

## Key Features

### Filesystem: Btrfs with Subvolumes

The system uses Btrfs with multiple subvolumes for organization and snapshot capabilities:

- `@` - Root filesystem (ephemeral with Impermanence)
- `@nix` - Nix store
- `@home` - User home directories
- `@persist` - Persistent data directory

All subvolumes use:
- `compress=zstd` - Zstandard compression
- `noatime` - Disable access time updates
- `discard=async` - Async TRIM support

### Disk Encryption: LUKS2

Full disk encryption using LUKS2 with:
- Keyfile stored in `/persist/etc/cryptsetup-keys.d/`
- Initrd keyfile support for automatic decryption
- Discard support for SSD optimization

### Impermanence

Ephemeral root filesystem that persists only specified directories and files:
- System directories: `/etc/nixos`, `/etc/ssh`, `/etc/NetworkManager/system-connections`
- User directories: `.config`, `.local`, `.ssh`, `Documents`, `Downloads`, `Projects`
- System files: `/etc/machine-id`

### Window Manager: Hyprland

Modern Wayland compositor with:
- Hardware-accelerated rendering
- Dynamic window tiling
- Custom keybindings and workspace management
- Integration with Waybar, Rofi, and other Wayland-native tools

### Home Manager

User configuration management with:
- Modular structure for easy customization
- Separate modules for each application
- Consistent theming (Catppuccin)
- XDG directory configuration

### Automated Installation

The `install.sh` script automates:
- Disk partitioning (GPT with EFI and LUKS partitions)
- LUKS encryption setup
- Btrfs filesystem and subvolume creation
- System installation
- Configuration staging
- Keyfile generation and setup

---

## Configuration Modules

The Home Manager configuration is organized into modular files for maintainability:

| Module | Description |
|--------|-------------|
| `bash.nix` | Bash shell configuration and settings |
| `cursor.nix` | Cursor theme configuration (Bibata-Modern-Ice) |
| `fastfetch.nix` | Fastfetch system information tool configuration |
| `hyprland.nix` | Hyprland window manager settings, keybindings, and window rules |
| `hyprlock.nix` | Screen lock configuration for Hyprland |
| `hyprpaper.nix` | Wallpaper manager configuration |
| `kitty.nix` | Kitty terminal emulator configuration |
| `neovim.nix` | Neovim text editor configuration |
| `rofi.nix` | Rofi application launcher and window switcher |
| `signal-desktop.nix` | Signal Desktop messaging application |
| `starship.nix` | Starship cross-shell prompt configuration |
| `waybar.nix` | Waybar status bar with system monitoring, workspaces, and controls |
| `wlogout.nix` | Wlogout logout/power menu configuration |
| `xdg.nix` | XDG directory and MIME type configuration |

Each module can be independently modified or disabled by commenting out the import in `home-manager/home.nix`.

---

## Installation

### Prerequisites

- NixOS installation media (live USB/CD)
- Root access
- `cryptsetup` installed on the live system
- Basic understanding of disk partitioning and encryption

### ⚠️ Warning

**The installation script will destroy all data on the target disk.** Ensure you have backups and are using the correct disk device.

### Installation Steps

1. **Clone or copy this repository** to the live NixOS system

2. **Review and modify** `configuration.nix` and `install.sh`:
   - Update `NIXOS_USER` in `install.sh` (default: `xychelsea`)
   - Update `NIXOS_HOST` in `install.sh` (default: `silverbox`)
   - Adjust disk device in `install.sh` (default: `/dev/nvme0n1`)
   - Review system packages and services in `configuration.nix`

3. **Run the installation script**:
   ```bash
   sudo bash install.sh
   ```

   For a complete disk wipe (overwrites with random data):
   ```bash
   sudo bash install.sh --wipe
   ```

4. **Follow the prompts**:
   - The script will handle partitioning, encryption, and installation
   - You'll be prompted to set a password for the LUKS container
   - You'll be prompted to set a user password

5. **Reboot** and remove the installation media

### Installation Script Features

The `install.sh` script:
- Creates GPT partition table with EFI and LUKS partitions
- Sets up LUKS2 encryption
- Creates Btrfs filesystem with subvolumes
- Generates hardware configuration
- Stages all configuration files
- Installs NixOS
- Sets up initrd keyfile for automatic decryption
- Configures UEFI boot entries

---

## Usage

### Switching Branches

To use a different hardware configuration:

```bash
cd /persist/etc/nixos
git checkout <branch-name>  # e.g., raspi4, silverbox, slimbox
sudo nixos-rebuild switch
```

### Rebuilding the System

After making configuration changes:

```bash
# Rebuild and switch to new configuration
sudo nixos-rebuild switch

# Rebuild and test without switching
sudo nixos-rebuild test

# Rebuild and boot into new configuration on next reboot
sudo nixos-rebuild boot
```

### Rebuilding Home Manager

For user configuration changes:

```bash
home-manager switch
```

### Customizing Configuration

1. **System-wide changes**: Edit `configuration.nix`
2. **User configuration**: Edit `home-manager/home.nix` or individual modules
3. **Application-specific**: Edit files in `home-manager/modules/`
4. **Hardware-specific**: Edit `hardware-configuration.nix` (be careful, this is auto-generated)

### Updating Channels

```bash
# Update NixOS channel
sudo nix-channel --update nixos

# Update Home Manager channel
nix-channel --update home-manager

# Rebuild after channel updates
sudo nixos-rebuild switch --upgrade
```

---

## System Information

### NixOS Version
- **State Version**: 25.05
- **Channel**: nixos-25.05

### Architecture
- **Primary**: x86_64-linux
- **Raspberry Pi**: aarch64-linux (raspi4 branch)

### Key Packages

**System Tools:**
- `git`, `curl`, `wget`, `jq`
- `docker`, `docker-compose`
- `clang`, `gcc`, `llvm`, `rustup`
- `python3`

**Desktop Environment:**
- `hyprland` - Window manager
- `waybar` - Status bar
- `rofi` - Application launcher
- `kitty` - Terminal emulator
- `neovim` - Text editor
- `hyprpaper` - Wallpaper manager
- `hyprlock` - Screen lock
- `wlogout` - Logout menu

**Applications:**
- `brave` - Web browser
- `signal-desktop` - Messaging
- `mullvad-vpn` - VPN client

**Theming:**
- `catppuccin-sddm` - SDDM theme
- `papirus-icon-theme` - Icon theme
- Custom Catppuccin GTK themes

### Services

- **NetworkManager** - Network management
- **Mullvad VPN** - VPN service
- **PipeWire** - Audio system
- **SDDM** - Display manager (Catppuccin theme)
- **Docker** - Container runtime
- **Btrfs auto-scrub** - Filesystem maintenance

### Boot Configuration

- **Bootloader**: GRUB with EFI support
- **Encryption**: LUKS2 with keyfile support
- **Theme**: Custom GRUB theme in `grub-theme/`
- **Kernel**: Latest Linux kernel packages

---

## Notes

### Personal Configuration

This is a **personal configuration repository** and is not intended for direct use without modification. Key considerations:

- **Username**: The configuration uses `xychelsea` as the default username. You'll need to update:
  - `configuration.nix` - User definition
  - `home-manager/home.nix` - Home directory paths
  - `install.sh` - Installation script variables

- **Hardware**: The `hardware-configuration.nix` is machine-specific and should be regenerated for your hardware:
  ```bash
  sudo nixos-generate-config
  ```

- **Hostname**: Default hostname is `default` in `configuration.nix`. Update for your system.

- **Time Zone**: Set to `America/New_York` in `configuration.nix`. Adjust as needed.

### Security Considerations

- **LUKS Password**: Choose a strong password for disk encryption
- **User Password**: The initial password in `configuration.nix` is a placeholder - change it immediately
- **SSH Keys**: Add your SSH keys to `/persist/home/<user>/.ssh/` after installation
- **Keyfile**: The LUKS keyfile is stored in `/persist/etc/cryptsetup-keys.d/` - ensure this directory has proper permissions

### Customization Tips

1. **Add packages**: Edit `environment.systemPackages` in `configuration.nix`
2. **Modify themes**: Update GTK theme settings in `home-manager/home.nix`
3. **Change keybindings**: Edit `home-manager/modules/hyprland.nix`
4. **Adjust workspaces**: Modify workspace count in `hyprland.nix`
5. **Add services**: Add to `services` section in `configuration.nix`

### Troubleshooting

- **Boot issues**: Check GRUB configuration and UEFI settings
- **Encryption problems**: Verify keyfile permissions and LUKS setup
- **Home Manager errors**: Run `home-manager switch --show-trace` for detailed errors
- **NixOS rebuild failures**: Use `sudo nixos-rebuild switch --show-trace` for debugging

### Getting Help

- [NixOS Manual](https://nixos.org/manual/nixos/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [NixOS Discourse](https://discourse.nixos.org/)

---

**Last Updated**: 2025

