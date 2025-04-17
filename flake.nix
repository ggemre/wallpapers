{
  description = "Flake for themed wallpapers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in {
    packages = nixpkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {inherit system;};
      wallpaperDir = ./images;

      randomWallpaperScript = pkgs.writeScriptBin "randomwallpaper" ''
        #!${pkgs.stdenv.shell}
        set -euo pipefail
        theme="''${1:-default}"
        wp_dir="$(${pkgs.nix}/bin/nix eval --raw .#packages.${system}.default)/share/wallpapers"
        find "$wp_dir/$theme" -maxdepth 3 -type f | shuf -n 1 | head -n 1
      '';

      wallpaperScript = pkgs.writeScriptBin "wallpaper" ''
        #!${pkgs.stdenv.shell}
        set -euo pipefail
        name="$1"
        wp_dir="$(nix eval --raw .#packages.${system}.default)/share/wallpapers"
        echo "$wp_dir/$name"
      '';
    in {
      default = pkgs.stdenv.mkDerivation {
        name = "wallpapers";
        src = wallpaperDir;
        installPhase = ''
          mkdir -p $out/share/wallpapers
          cp -r $src/* $out/share/wallpapers/
        '';
      };

      # Return a random wallpaper, optionally provide a theme to filter by
      random-wallpaper = pkgs.symlinkJoin {
        name = "randomwallpaper";
        paths = [
          pkgs.coreutils
          pkgs.findutils
          randomWallpaperScript
        ];
      };

      # Return a specific wallpaper given a path
      wallpaper = pkgs.symlinkJoin {
        name = "wallpaper";
        paths = [
          pkgs.coreutils
          wallpaperScript
        ];
      };
    });
  };
}
