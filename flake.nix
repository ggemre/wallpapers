{
  description = "Flake for my wallpapers";

  outputs = { self, nixpkgs }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    wallpaperPath = self + "/images";
  in {
    paths.wallpapers = wallpaperPath;

    packages = nixpkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      wallpapers = pkgs.stdenv.mkDerivation {
        name = "wallpapers";
        src = wallpaperPath;
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out
          cp -r $src/* $out/
        '';
      };

      default = self.packages.${system}.wallpapers;
    });
  };
}
