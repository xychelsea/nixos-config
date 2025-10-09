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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "snd_bcm2835.enable_hdmi=1"
      "snd_bcm2835.enable_headphones=1"
    ];
    loader = {
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
      generic-extlinux-compatible = {
        enable = true;
      };
      grub = {
        enable = false;
        efiSupport = true;
        devices = [ "nodev" ];
        theme = ./grub-theme;
        gfxmodeEfi = "auto";
        gfxpayloadEfi = "keep";
        fontSize = 36;
        enableCryptodisk = true;
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
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/bluetooth"
        "/var/lib/docker"
        "/projects"
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
      raspberrypi-eeprom
      rofi
      rustup
      sassc
      signal-desktop-bin
      wget
      wlogout
    ];
  };
  fileSystems = {
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
    users.xychelsea = import ./home-manager/home.nix;
  };
  system.stateVersion = "25.05";
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
  imports = [
    <nixos-hardware/raspberry-pi/4>
    ./hardware-configuration.nix
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  networking.hostName = "raspi4";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    dconf = {
      enable = true;
    };
  };
  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/persist" ];
    };
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        package = pkgs.kdePackages.sddm;
        theme = "catppuccin-mocha";
      };
      defaultSession = "hyprland-uwsm";
    };
    fstrim = {
      enable = true;
    };
    mullvad-vpn = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pulseaudio = {
      enable = false;
    };
    xserver = {
      enable = true;
    };
  };
  users.users.xychelsea = {
    isNormalUser = true;
    description = "Primary user account";
    uid = 1000;
    group = "users";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    initialPassword = "not-a-real-hardcoded-password";
    shell = pkgs.bashInteractive;
    packages = with pkgs; [
    ];
  };
  security.rtkit.enable = true;
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  nixpkgs.overlays = [ (import "${homeManager}/overlay.nix") ];
  nixpkgs.hostPlatform = "aarch64-linux";
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      "data-root" = "/persist/var/lib/docker";
      default-address-pools = [
        {
          base = "10.82.0.0/16";
          size = 24;
        }
      ];
    };
    rootless.enable = true;
  };
}

