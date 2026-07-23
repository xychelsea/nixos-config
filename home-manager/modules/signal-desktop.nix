{ config, pkgs, lib, ... }:
let
  calfmoonSrc = pkgs.fetchFromGitHub {
    owner = "CalfMoon";
    repo = "signal-desktop";
    rev = "658cb182d49dc6ba3085c7b63db0987e875a29bf";
    sha256 = "sha256-dWT3hG2uGhwpNgGHjwVmzci68upUVe5ktoeaPrNZ3q8=";
  };
  chosenCss = "catppuccin-mocha.css";
  asarCli   = pkgs.asar;
  signal-desktop-calfmoon = pkgs.signal-desktop.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ asarCli pkgs.gnused ];
    postInstall = (old.postInstall or "") + ''
      echo "==> Applying CalfMoon theme to Signal Desktop (${chosenCss})"
      workdir="$(mktemp -d)"
      appAsarPath="$out/share/signal-desktop/app.asar"

      pushd "$workdir" >/dev/null
      ${asarCli}/bin/asar extract "$appAsarPath" extracted

      install -Dm0644 "${calfmoonSrc}/themes/${chosenCss}" \
        "extracted/stylesheets/${chosenCss}"

      manifest="extracted/stylesheets/manifest.css"
      if ! grep -q "${chosenCss}" "$manifest"; then
        sed -i "1i @import \"${chosenCss}\";" "$manifest"
      fi

      ${asarCli}/bin/asar pack extracted new-app.asar
      install -m0644 new-app.asar "$appAsarPath"

      popd >/dev/null
      rm -rf "$workdir"
    '';
  });
in
{
  home.packages = [ signal-desktop-calfmoon ];
}

