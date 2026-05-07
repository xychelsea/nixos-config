{ config, pkgs, lib, ... }:
let
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
  };
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
  boot = {
    initrd = {
    };
    kernelPackages = pkgs.linuxPackages_6_12;
    kernelParams = [
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
        enableCryptodisk = false;
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
      "zfs"
    ];
    zfs = {
      extraPools = [ "tank" ];
      forceImportRoot = false;
    };
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
          ".local"
          ".ssh"
          "Documents"
          "Downloads"
        ];
        files = [
        ];
      };
      directories = [
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
      curl
      clang
      docker
      docker-compose
      eza
      gcc
      git
      glib
      home-manager
      jq
      kitty.terminfo
      llvm
      neovim
      python3
      rustup
      wget
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
  };
  hardware = {
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
    firewall = {
      allowedTCPPorts = [ 36122 ];
    };
    hostName = "cloudbox";
    hostId = "1a2b3c4d";
    interfaces = {
      enp5s0 = {
        useDHCP = true;
      };
    };
    networkmanager = {
      enable = true;
    };
    useDHCP = false;
    wireless = {
      enable = false;
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
      allowUnfree = false;
    };
    hostPlatform = "x86_64-linux";
    overlays = [ (import "${homeManager}/overlay.nix") ];
  };
  programs = {
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
    fstrim = {
      enable = true;
    };
    openssh = {
      enable = true;
    };
  };
  system = {
    stateVersion = "25.11";
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
    rootless.enable = true;
  };
}

