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
    consoleLogLevel = 7;
    initrd = {
      availableKernelModules = [
        "xhci_hcd"
        "xhci_tegra"
        "usb_storage"
        "sd_mod"
        "nvme"
        "nvme_core"
        "pcie_tegra194"
        "phy_tegra194_p2u"
        "ahci"
      ];
      kernelModules = [
        "xhci_tegra"
        "usb_storage"
        "nvme"
        "pcie_tegra194"
        "ahci"
      ];
    };
    kernelModules = [
      "lan743x"
      "r8168"
      "can"
      "can_raw"
      "mttcan"
    ];
    kernelParams = [
      "console=ttyTCU0,115200n8"
      "console=tty0"
      "efi=runtime"
      "pci=pcie_bus_perf"
      "nvme.use_threaded_interrupts=1"
      "swiotlb=2048"
      "firmware_class.path=/etc/firmware"
      # Remove after USB stability has been verified.
      "usbcore.autosuspend=-1"
      # Remove after PCIe devices have been verified with ASPM enabled.
      "pcie_aspm=off"
      # Remove before enabling NVIDIA graphics.
      "nomodeset"
    ];
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        # Enable this only after the basic system boots reliably.
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot";
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
      can-utils
      curl
      clang
      dtc
      docker
      docker-compose
      efibootmgr
      ethtool
      eza
      gcc
      git
      glib
      home-manager
      jq
      kitty.terminfo
      llvm
      neovim
      nvme-cli
      pciutils
      python3
      smartmontools
      screen
      rustup
      usbutils
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
    "/boot" = {
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
  };
  hardware = {
    graphics = {
      # Enable this only after the basic system boots reliably.
      enable = false;
    };
    nvidia-jetpack = {
      carrierBoard = "devkit";
      console = {
        enable = true;
      };
      enable = true;
      majorVersion = "7";
      som = "orin-nx";
      super = true;
      # Enable this only after the basic system boots reliably.
      configureCuda = false;
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
    ./vendor/jetpack-nixos/modules
    (import "${homeManager}/nixos")
    (import "${impermanence}/nixos.nix")
  ];
  networking = {
    firewall = {
      allowedTCPPorts = [ 36122 ];
    };
    hostName = "mediabox";
    hostId = "1a2b3c4d";
    interfaces = {
    };
    networkmanager = {
      enable = true;
    };
    useDHCP = false;
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
    hostPlatform = lib.mkDefault "aarch64-linux";
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
      ports = [ 36122 ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
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
    rootless.enable = true;
  };
}

