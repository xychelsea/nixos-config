{ config, pkgs, lib, ... }:
let
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
  };
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
  boot = {
    consoleLogLevel = 4;
    initrd = {
      luks.devices.nixos = {
        allowDiscards = true;
        keyFile = "/cryptroot.key";
      };
      secrets = {
        "/cryptroot.key" = "/persist/etc/cryptsetup-keys.d/cryptroot.key";
      };
    };
    kernelPackages = pkgs.linuxPackages;
    kernelModules = [
    ];
    kernelParams = [
      "amdgpu.backlight=1"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      generic-extlinux-compatible = {
        enable = false;
      };
      grub = {
        devices = [ "nodev" ];
        enable = true;
        enableCryptodisk = true;
        efiSupport = true;
        fontSize = 36;
        fsIdentifier = "provided";
        gfxmodeEfi = "auto";
        gfxpayloadEfi = "keep";
        theme = ./grub-theme;
      };
    };
    supportedFilesystems = [
      "btrfs"
    ];
  };
  console = {
    enable = true;
    keyMap = "us";
  };
  environment = {
    persistence."/persist" = {
      users.xychelsea = {
        directories = [
          ".config"
          ".cursor"
          ".claude"
          ".local"
          ".ssh"
          ".themes"
          ".zoom"
          "Documents"
          "Downloads"
        ];
        files = [
          ".claude.json"
        ];
      };
      directories = [
        "/etc/cryptsetup-keys.d"
        "/etc/mullvad-vpn"
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
        "/etc/ssh"
        "/projects"
        "/var/lib/bluetooth"
        "/var/lib/docker"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
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
      codeberg-cli
      code-cursor
      curl
      clang
      docker
      docker-compose
      eza
      ffmpeg-full
      gcc
      git
      glab
      glib
      gnome-shell
      gnome-themes-extra
      home-manager
      hyprcursor
      hypridle
      hyprlock
      hyprpaper
      hyprpicker
      hyprpolkitagent
      jq
      kitty.terminfo
      llvm
      mullvad
      mullvad-vpn
      neovim
      nvidia-container-toolkit
      papirus-icon-theme
      pavucontrol
      pyprland
      python3
      rofi
      rustup
      sassc
      slack
      spotify
      vlc
      wget
      wlogout
      zoom-us
    ];
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
        "noatime"
        "discard=async" 
      ];
    };
    "/boot/efi" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/home" = {
      device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "defaults" ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
        "discard=async"
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
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.liberation
      nerd-fonts.noto
      nerd-fonts.roboto-mono
      vista-fonts
    ];
  };
  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      modesetting = {
        enable = true;
      };
      nvidiaSettings = true;
      open = false;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
    };
    nvidia-container-toolkit = {
      enable = true;
    };
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
    ./hardware-configuration.nix
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  networking = {
    hostName = "gamebox";
    networkmanager = {
      enable = true;
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
    config = {
      allowUnfree = true;
    };
    hostPlatform = "x86_64-linux";
    overlays = [ (import "${homeManager}/overlay.nix") ];
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
        extraPackages = [ pkgs.catppuccin-sddm ];
        package = pkgs.kdePackages.sddm;
        theme = "catppuccin-mocha-mauve";
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
    oo7 = {
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
      videoDrivers = ["nvidia"];
    };
  };
  system = {
    stateVersion = "26.05";
  };
  systemd = {
    tmpfiles = {
      rules = [
        "z / 0755 root root - -"
      ];
    };
  };
  time = {
    timeZone = "America/New_York";
  };
  users.users = {
    xychelsea = {
      description = "Chelsea E. Manning";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
      ];
      group = "users";
      hashedPasswordFile = "/persist/secrets/xychelsea.passwd";
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
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}

