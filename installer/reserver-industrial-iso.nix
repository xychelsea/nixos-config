let
  jetpack = (
    import ../vendor/flake-compat {
      src = ../vendor/jetpack-nixos;
    }
  ).outputs;
in
  jetpack.packages.x86_64-linux.iso_minimal_jp7
