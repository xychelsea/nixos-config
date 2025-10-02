{ config, pkgs, lib, ... }:
let
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  };
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
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
    ./hardware-configuration.nix
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  console.keyMap = "us";
  boot.loader.efi = {
    efiSysMountPoint = "/boot/efi";
    canTouchEfiVariables = true;
  };
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      theme = ./grub-theme;
      gfxmodeEfi = "auto";
      gfxpayloadEfi = "keep";
      fontSize = 36;
      enableCryptodisk = true;
    };
    initrd = {
      luks.devices.nixos = {
        allowDiscards = true;
        keyFile = "/cryptroot.key";
      };
      secrets = {
        "/cryptroot.key" = "/persist/etc/cryptsetup-keys.d/cryptroot.key";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
  networking.hostName = "silverbox";
  networking.networkmanager.enable = true;
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
  fileSystems."/persist" = {
    device = "/dev/disk/by-label/nixos";
    neededForBoot = true;
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
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
  security.rtkit.enable = true;
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/persist" ];
  };
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "catppuccin-mocha";
    };
    defaultSession = "hyprland-uwsm";
  };
  services.fstrim.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;
  services.xserver = {
    enable = true;
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
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
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
  }
  nixpkgs.overlays = [ (import "${homeManager}/overlay.nix") ];
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
      llvm
      neovim
      papirus-icon-theme
      pavucontrol
      pyprland
      python3
      rofi
      rustup
      sassc
      signal-desktop-bin
      wget
      wlogout
    ];
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.xychelsea = import ./home-manager/home.nix;
  };
}

