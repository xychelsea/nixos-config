{ config, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      eza
      git
      home-manager
      jq
      kitty.terminfo
      neovim
      python3
    ];
  };
  fonts = {
    packages = with pkgs; [
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
    ];
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      xychelsea = import /etc/nix-darwin/home-manager/home.nix;
    };
  };
  imports = [
    <home-manager/nix-darwin>
  ];
  nixpkgs = {
    config = {
      allowUnfree = false;
    };
    hostPlatform = "aarch64-darwin";
  };
  system = {
    stateVersion = 6;
  };
  users.users.xychelsea = {
    name = "xychelsea";
    home = "/Users/xychelsea";
  };
}
