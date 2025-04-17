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
    packages = nixpkgs.lib.genAttrs systems (
      system: let
        pkgs = import nixpkgs {inherit system;};
        wallpaperDir = ./images;

        wallpaperPackage = pkgs.stdenv.mkDerivation {
          name = "wallpapers";
          src = wallpaperDir;
          installPhase = ''
            mkdir -p $out/share/wallpapers
            cp -r $src/* $out/share/wallpapers/
          '';
        };

        wallpaperPath = pkgs.runCommand "wallpaper-path" {} ''
          mkdir -p $out
          ln -s ${wallpaperPackage}/share/wallpapers $out
        '';

        randomWallpaperScript = pkgs.writeScriptBin "randomwallpaper" ''
          #!${pkgs.stdenv.shell}
          set -euo pipefail
          theme="''${1:-default}"
          find "${wallpaperPackage}/share/wallpapers/$theme" -maxdepth 3 -type f | shuf -n 1 | head -n 1
        '';

        # TODO: this does not validate that the path exists
        wallpaperScript = pkgs.writeScriptBin "wallpaper" ''
          #!${pkgs.stdenv.shell}
          set -euo pipefail
          name="$1"
          echo "${wallpaperPackage}/share/wallpapers/$name"
        '';
      in {
        default = wallpaperPackage;
        wallpaperPath = wallpaperPath;

        # Return a random wallpaper, optionally filter by theme
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
      }
    );
  };
}
