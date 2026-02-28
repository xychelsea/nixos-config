{ pkgs, ... }:
{
  programs = {
    git = {
      enable = true;
      settings = {
        include = {
          path = "~/.config/git/private";
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
  };
}
