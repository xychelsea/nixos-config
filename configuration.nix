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
    <nixos-hardware/raspberry-pi/4>
    ./hardware-configuration.nix
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  console = {
    enable = false;
    keyMap = "us";
  };
  boot.loader.efi = {
    efiSysMountPoint = "/boot/efi";
    canTouchEfiVariables = true;
  };
  boot = {
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
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
  };
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
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.bitstream-vera-sans-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.liberation
    nerd-fonts.noto
    nerd-fonts.roboto-mono
  ];
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
      libraspberrypi
      llvm
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
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.xychelsea = import ./home-manager/home.nix;
  };
}

