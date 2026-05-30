{ pkgs, ... }:
{
  programs.bash = {
    bashrcExtra = ''
case $- in
  *i*) ;;
  *) return;;
esac
if [[ $(tty) == *"ttys"* ]]; then
  fastfetch
fi

eval "$(starship init bash)"
    '';
    enable = true;
    enableCompletion = true;
    historyFile = "/dev/null";
    historyFileSize = 0;
    historyIgnore = [];
    shellAliases = {
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      shutdown = "systemctl poweroff";
    };
  };
}
