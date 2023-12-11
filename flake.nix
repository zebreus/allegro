{
  description = "Allegro Common Lisp";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let

        # alisp = (
        #   let
        #     pkgs = nixpkgs.legacyPackages.${system};
        #   in
        #   pkgs.stdenv.mkDerivation rec {
        #     pname = "alisp";
        #     version = "10.1";
        #     src = pkgs.fetchzip
        #       {
        #         url = "https://franz.com/ftp/pub/acl10.1express/linuxamd64.64/acl${version}express-linux-x64.tbz2";
        #         hash = "sha256-7LN/jxjJoJctIVPrW3n27smwXzm0w8jUrbS+Z8P1Y5Y=";
        #       };
        #     buildInputs = [ pkgs.autoPatchelfHook pkgs.gdbm pkgs.openssl pkgs.libz pkgs.makeWrapper ];
        #     runtimeDependencies = [ pkgs.gdbm pkgs.openssl pkgs.libz ];
        #     prePatch = ''
        #       patchelf --replace-needed libgdbm.so.2 libgdbm.so code/ndbm_wrappers.so
        #     '';
        #     buildPhase = ''
        #     '';
        #     installPhase = ''
        #       mkdir -p $out/bin
        #       cp -r $(pwd) $out/allegro

        #       makeWrapper $out/allegro/alisp $out/bin/alisp \
        #         --suffix PATH : ${pkgs.lib.makeBinPath [
        #           pkgs.openssl
        #         ]} \
        #         --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
        #           pkgs.openssl
        #           pkgs.zlib
        #         ]}
        #     '';
        #   }
        # );

        pkgs = nixpkgs.legacyPackages.${system};

        basicAlisp = pkgs.callPackage makeAllegroLispPackage {
          binaryName = "alisp";
          extraProgramsAtRuntime = [ ];
          baseImage = "alisp.dxl";
          buildLispImageArgs = "";
        };

        makeAllegroLispPackage =
          { lib
          , stdenv
          , fetchzip
          , autoPatchelfHook
          , gdbm
          , openssl_3
          , libz
          , makeWrapper
          , binaryName ? "alisp"
          , extraProgramsAtRuntime ? [ ]
          , baseImage ? "alisp.dxl"
          , buildLispImageArgs ? ""
          , description ? "Allegro Common Lisp"
          }: (

            stdenv.mkDerivation rec {
              pname = binaryName;
              version = "10.1";
              src = fetchzip
                {
                  url = "https://franz.com/ftp/pub/acl10.1express/linuxamd64.64/acl${version}express-linux-x64.tbz2";
                  hash = "sha256-7LN/jxjJoJctIVPrW3n27smwXzm0w8jUrbS+Z8P1Y5Y=";
                };
              buildInputs = [ autoPatchelfHook gdbm openssl_3 libz makeWrapper ];
              runtimeDependencies = [ gdbm openssl_3 libz ];
              prePatch = ''
                patchelf --replace-needed libgdbm.so.2 libgdbm.so code/ndbm_wrappers.so
              '';
              buildPhase = ''
            '';
              installPhase = ''
                mkdir -p $out/bin
                cp -r ./ $out/allegro

                mv $out/allegro/${baseImage} $out/allegro/nix-temporary-image.dxl
                ${
                  if buildLispImageArgs != "" then ''
                  BUILD_IMAGE_SCRIPT=$PWD/buildImage.lisp
                  echo "(build-lisp-image \"$out/allegro/${binaryName}.dxl\" ${buildLispImageArgs})" > $BUILD_IMAGE_SCRIPT
              
                  cd $out/allegro
                  ${lib.getExe basicAlisp} -I $out/allegro/nix-temporary-image.dxl -L $BUILD_IMAGE_SCRIPT --kill >&2
                  cd -
                  ''
                  else ''
                   mv $out/allegro/nix-temporary-image.dxl $out/allegro/${binaryName}.dxl
                  ''
                }

                mv $out/allegro/alisp $out/allegro/__nix-temporary-binary
                mv $out/allegro/__nix-temporary-binary $out/allegro/${binaryName}
                
                makeWrapper $out/allegro/${binaryName} $out/bin/${binaryName} \
                  --prefix PATH : ${pkgs.lib.makeBinPath ([
                    pkgs.openssl_3
                  ] ++ extraProgramsAtRuntime)} \
                  --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                    pkgs.openssl_3
                    pkgs.zlib
                  ]}
              '';
              meta = with pkgs.lib; {
                description = description;
                homepage = "https://franz.com/products/allegrocl/";
                platforms = platforms.linux;
                mainProgram = binaryName;
              };
            }
          );
      in

      rec {
        name = "allegro";

        packages.allegro-express = pkgs.callPackage makeAllegroLispPackage {
          binaryName = "allegro-express";
          extraProgramsAtRuntime = [ pkgs.firefox ];
          baseImage = "allegro-express.dxl";
        };

        packages.alisp = pkgs.callPackage makeAllegroLispPackage {
          binaryName = "alisp";
          baseImage = "alisp.dxl";
        };

        packages.allegro = pkgs.callPackage makeAllegroLispPackage {
          binaryName = "allegro";
          extraProgramsAtRuntime = [ pkgs.firefox ];
          baseImage = "allegro-express.dxl";
          buildLispImageArgs = ":case-mode :case-sensitive-lower";
        };

        packages.mlisp = pkgs.callPackage makeAllegroLispPackage {
          binaryName = "mlisp";
          baseImage = "alisp.dxl";
          buildLispImageArgs = ":case-mode :case-sensitive-lower";
        };

        packages.default = packages.allegro;
      }
    );
}
