{ config, pkgs, lib, ... }:
let
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  jetpack = (
    import ./vendor/flake-compat {
      src = ./vendor/jetpack-nixos;
    }
  ).outputs;
in
{
  boot = {
    consoleLogLevel = 4;
    extraModulePackages = lib.mkForce [
      (config.boot.kernelPackages.nvidia-oot-modules.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          chmod +x nvdisplay/kernel-open/pahole.sh
          chmod +x unifiedgpudisp/kernel-open/pahole.sh
          patchShebangs nvdisplay/kernel-open/pahole.sh
          patchShebangs unifiedgpudisp/kernel-open/pahole.sh
        '';
      }))
    ];
    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "nvme_core"
        "pcie_tegra194"
        "phy_tegra194_p2u"
        "sd_mod"
        "usb_storage"
        "xhci_hcd"
        "xhci_tegra"
      ];
      kernelModules = [
        "ahci"
        "nvme"
        "pcie_tegra194"
        "usb_storage"
        "xhci_tegra"
      ];
      secrets = {
      };
      supportedFilesystems = [
        "btrfs"
      ];
    };
    kernel = {
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
    ];
    kernelPatches = [
      {
        name = "arm64-libbpf-build-compat";
        patch = ./kernel-bpf-compat.patch;
      }
    ];
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
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
      can-utils
      curl
      clang
      dtc
      docker
      docker-compose
      efibootmgr
      ethtool
      eza
      ffmpeg
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
      rustup
      screen
      smartmontools
      usbutils
      tpm2-tools
      wget
    ];
  };
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "defaults" ];
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
      enable = true;
    };
    nvidia-container-toolkit = {
      enable = true;
    };
    nvidia-jetpack = {
      carrierBoard = "devkit";
      configureCuda = true;
      console = {
        enable = true;
      };
      enable = true;
      majorVersion = "7";
      som = "orin-nx";
      super = true;
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
    jetpack.nixosModules.default
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
      enp8p1s0 = {
        useDHCP = true;
      };
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
    overlays = [
      (import "${homeManager}/overlay.nix")
    ];
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
    stateVersion = "26.11";
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
        "video"
        "render"
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
      enable = false;
    };
  };
}

