{ config, pkgs, lib, ... }:
{
  imports = [
    ./modules/bash.nix
    ./modules/fastfetch.nix
    ./modules/git.nix
    ./modules/starship.nix
    ./modules/zsh.nix
  ];

  home = {
    homeDirectory = "/home/xychelsea";
    file = { };
    packages = [ ];
    sessionVariables = {
      EDITOR = "nvim";
    };
    stateVersion = "25.11";
    username = "xychelsea";
  };
}

