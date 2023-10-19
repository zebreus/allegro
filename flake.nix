{
  description = "Allegro Common Lisp";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      rec {
        name = "allegro";

        packages.allegro = (
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          pkgs.stdenv.mkDerivation rec {
            pname = "allegro";
            version = "10.1";
            src = pkgs.fetchzip
              {
                url = "https://franz.com/ftp/pub/acl10.1express/linuxamd64.64/acl${version}express-linux-x64.tbz2";
                hash = "sha256-7LN/jxjJoJctIVPrW3n27smwXzm0w8jUrbS+Z8P1Y5Y=";
              };
            buildInputs = [ pkgs.autoPatchelfHook pkgs.gdbm pkgs.openssl pkgs.libz pkgs.makeWrapper ];
            runtimeDependencies = [ pkgs.gdbm pkgs.openssl pkgs.libz ];
            prePatch = ''
              patchelf --replace-needed libgdbm.so.2 libgdbm.so code/ndbm_wrappers.so
            '';
            buildPhase = ''
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp -r ./ $out/allegro
              cp $out/allegro/allegro-express $out/allegro/allegro

              BUILD_IMAGE_SCRIPT=$PWD/buildModernImage.lisp

              echo "(build-lisp-image \"$out/allegro/allegro.dxl\" :case-mode :case-sensitive-lower)" > $BUILD_IMAGE_SCRIPT
              
              cd $out/allegro
              ${packages.alisp}/bin/alisp -I $out/allegro/allegro-express.dxl -L $BUILD_IMAGE_SCRIPT --kill >&2
              cd -

              makeWrapper $out/allegro/allegro $out/bin/allegro \
                --suffix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.openssl
                  pkgs.firefox
                ]} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                  pkgs.openssl
                  pkgs.zlib
                ]}
            '';
            meta = with pkgs.lib; {
              description = "Allegro Common Lisp";
              homepage = "https://franz.com/products/allegrocl/";
              platforms = platforms.linux;
              mainProgram = "allegro"
              ;
            };
          }
        );

        packages.alisp = (
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          pkgs.stdenv.mkDerivation rec {
            pname = "alisp";
            version = "10.1";
            src = pkgs.fetchzip
              {
                url = "https://franz.com/ftp/pub/acl10.1express/linuxamd64.64/acl${version}express-linux-x64.tbz2";
                hash = "sha256-7LN/jxjJoJctIVPrW3n27smwXzm0w8jUrbS+Z8P1Y5Y=";
              };
            buildInputs = [ pkgs.autoPatchelfHook pkgs.gdbm pkgs.openssl pkgs.libz pkgs.makeWrapper ];
            runtimeDependencies = [ pkgs.gdbm pkgs.openssl pkgs.libz ];
            prePatch = ''
              patchelf --replace-needed libgdbm.so.2 libgdbm.so code/ndbm_wrappers.so
            '';
            buildPhase = ''
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp -r $(pwd) $out/allegro
              
              makeWrapper $out/allegro/alisp $out/bin/alisp \
                --suffix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.openssl
                  pkgs.firefox
                ]} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                  pkgs.openssl
                  pkgs.zlib
                ]}
            '';
            meta = with pkgs.lib; {
              description = "Allegro Common Lisp";
              homepage = "https://franz.com/products/allegrocl/";
              platforms = platforms.linux;
              mainProgram = "alisp";
            };
          }
        );

        packages.default = packages.allegro;
      }
    );
}
