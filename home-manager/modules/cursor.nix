{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.appimage-run
    (pkgs.writeShellScriptBin "cursor" ''
      exec ${pkgs.appimage-run}/bin/appimage-run "${config.home.homeDirectory}/.local/opt/cursor/Cursor.AppImage" "$@"
    '')
  ];
  home.file.".local/share/applications/cursor.desktop".text = ''
    [Desktop Entry]
    Name=Cursor
    Exec=${pkgs.appimage-run}/bin/appimage-run %k
    Type=Application
    Terminal=false
    Categories=Development;IDE;
    MimeType=application/x-iso9660-appimage;
    X-AppImage-Path=${config.home.homeDirectory}/.local/opt/cursor/Cursor.AppImage
    Icon=code
  '';
}

