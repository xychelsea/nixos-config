{ pkgs, ... }:
{
  programs.zsh = {
    initContent = ''
if [[ $(tty) == *"ttys"* ]]; then
  fastfetch
fi

eval "$(starship init zsh)"
    '';
    enable = true;
    enableCompletion = true;
    history = {
      path = "/dev/null";
      save = 0;
      size = 100;
    };
    shellAliases = {
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      shutdown = "systemctl poweroff";
    };
  };
}
