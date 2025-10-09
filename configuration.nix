{ config, pkgs, lib, ... }:
let
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  };
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
  boot = {
    initrd = {
      luks.devices.nixos = {
        allowDiscards = true;
        keyFile = "/cryptroot.key";
      };
    };
    kernelPackages = pkgs.linuxPackages_rpi4;
    kernelParams = [
      "snd_bcm2835.enable_hdmi=1"
      "snd_bcm2835.enable_headphones=1"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot/efi";
      };
      generic-extlinux-compatible = {
        enable = true;
      };
      grub = {
        devices = [ "nodev" ];
        enable = false;
        enableCryptodisk = true;
        efiSupport = true;
        fontSize = 36;
        gfxmodeEfi = "auto";
        gfxpayloadEfi = "keep";
        theme = ./grub-theme;
      };
    };
    supportedFilesystems = [ "btrfs" ];
  };
  console = {
    enable = false;
    keyMap = "us";
  };
  environment = {
    persistence."/persist" = {
      users.xychelsea = {
        directories = [
          ".config"
          ".local"
          ".ssh"
          ".themes"
          "Documents"
          "Downloads"
          "Projects"
        ];
        files = [
          ".bash_history"
          ".zsh_history"
        ];
      };
      directories = [
        "/etc/cryptsetup-keys.d"
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/projects"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/bluetooth"
        "/var/lib/docker"
      ];
      files = [
        "/etc/machine-id"
      ];
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
    systemPackages = with pkgs; [
      adwaita-qt
      brave
      catppuccin-sddm
      curl
      clang
      docker
      docker-compose
      eza
      gcc
      git
      glib
      gnome-shell
      gnome-themes-extra
      gtk-engine-murrine
      jq
      home-manager
      hyprcursor
      hypridle
      hyprlock
      hyprpaper
      hyprpicker
      hyprpolkitagent
      libraspberrypi
      llvm
      mullvad
      mullvad-vpn
      neovim
      papirus-icon-theme
      pavucontrol
      pyprland
      python3
      raspberrypifw
      raspberrypi-eeprom
      rofi
      rustup
      sassc
      signal-desktop-bin
      ubootRaspberryPi4_64bit
      wget
      wlogout
    ];
  };
  fileSystems = {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/persist" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@persist"
        "compress=zstd"
        "noatime"
        "discard=async"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
        "discard=async"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
        "noatime"
        "discard=async"
      ];
    };
  };
  fonts = {
    enableGhostscriptFonts = true;
    fontDir = {
      enable = true;
    };
    packages = with pkgs; [
      corefonts
      font-awesome
      nerd-fonts.bitstream-vera-sans-mono
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.liberation
      nerd-fonts.noto
      nerd-fonts.roboto-mono
      vistafonts
    ];
  };
  hardware = {
    enableRedistributableFirmware = true;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      xychelsea = import ./home-manager/home.nix;
    };
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  imports = [
    <nixos-hardware/raspberry-pi/4>
    ./hardware-configuration.nix
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  networking = {
    hostName = "raspi4";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  nixpkgs = {
    hostPlatform = "aarch64-linux";
    overlays = [ (import "${homeManager}/overlay.nix") ];
    config = {
      allowUnfree = true;
    };
  };
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    dconf = {
      enable = true;
    };
  };
  security = {
    rtkit = {
      enable = true;
    };
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  services = {
    btrfs = {
      autoScrub = {
        enable = true;
        fileSystems = [ "/persist" ];
      };
    };
    displayManager = {
      defaultSession = "hyprland-uwsm";
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        theme = "catppuccin-mocha";
        wayland = {
          enable = true;
        };
      };
    };
    fstrim = {
      enable = true;
    };
    mullvad-vpn = {
      enable = true;
    };
    pipewire = {
      alsa = {
        enable = true;
        support32Bit = true;
      };
      enable = true;
      pulse = {
        enable = true;
      };
    };
    pulseaudio = {
      enable = false;
    };
    xserver = {
      enable = true;
    };
  };
  system = {
    activationScripts.populateRpiFirmware = {
      text = ''
        set -eu
        dst=/boot/firmware
        mkdir -p "$dst"

        # Copy firmware files (start4.elf, fixups, overlays, dtbs) if missing
        if [ ! -f "$dst/start4.elf" ]; then
          cp -av ${pkgs.raspberrypifw}/share/raspberrypi/boot/* "$dst"/
        fi

        # Ensure U-Boot binary is present for the extlinux hand-off
        if [ ! -f "$dst/u-boot.bin" ]; then
          cp -av ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin "$dst"/
        fi

        # Provide a sane default config.txt if none exists
        if [ ! -f "$dst/config.txt" ]; then
          cat >"$dst/config.txt" <<'EOF'
arm_64bit=1
# Use KMS driver; enables HDMI and 3D on Pi 4
dtoverlay=vc4-kms-v3d
# Optional but helpful during bring-up
enable_uart=1
# Audio on; you can tune later
dtparam=audio=on
EOF
        fi
      '';
    };
    stateVersion = "25.05";
  };
  time = {
    timeZone = "America/New_York";
  };
  users.users = {
    xychelsea = {
      description = "Primary user account";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
      ];
      group = "users";
      initialPassword = "not-a-real-hardcoded-password";
      isNormalUser = true;
      packages = with pkgs; [
      ];
      shell = pkgs.bashInteractive;
      uid = 1000;
    };
  };
  virtualisation.docker = {
    daemon.settings = {
      "data-root" = "/persist/var/lib/docker";
      default-address-pools = [
        {
          base = "10.82.0.0/16";
          size = 24;
        }
      ];
    };
    enable = true;
    rootless.enable = true;
  };
}

