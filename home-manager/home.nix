{ config, pkgs, ... }:
{
  imports = [
    ./modules/aerospace.nix
    ./modules/bash.nix
    ./modules/fastfetch.nix
    ./modules/git.nix
    ./modules/jankyborders.nix
    ./modules/kitty.nix
    ./modules/starship.nix
    ./modules/zsh.nix
  ];

  home = {
    homeDirectory = "/Users/xychelsea";
    packages = with pkgs; [
      jankyborders
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
    stateVersion = "25.11";
  };
}
