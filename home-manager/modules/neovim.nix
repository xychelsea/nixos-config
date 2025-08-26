{ pkg, ... }:
let
  nvchat = pkgs.fetchFromGitHub {
    owner = "NvChad";
    repo = "NvChad";
    rev = "v2.5";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [ ripgrep fd git ]
  }
  xdg.configFile."nvim".source = nvchad;
  xdg.configFile."nvim".recursive = true;
  xdg.configFile."nvim/lua/custom".source = myCustom;
  xdg.configFile."nvim/lua/custom".recursive = true;
}

