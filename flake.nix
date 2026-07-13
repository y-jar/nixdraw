{
  description = "Nix declaired fork of Excalidraw";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; #

  # vars and logic for it to work
  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # [yarn package]
    excalidrawPackage = pkgs.stdenv.mkDerivation (finalAttrs: {
      name = "excalidraw";
      src = ./.;

      nativeBuildInputs = with pkgs; [
        nodejs
        yarn
        python3 # node-gyp needs this sometimes
      ];

      # Yarn needs a writable home and cache
      preBuild = ''
        export HOME=$TMPDIR
        export YARN_CACHE_FOLDER=$TMPDIR/yarn-cache
      ''; # end of prebuild

      buildPhase = ''
        runHook preBuild
        yarn install --frozen-lockfile --ignore-scripts
        yarn build
        runHook postBuild
      ''; # end of build phase

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r build/* $out/
        runHook postInstall
      ''; # end of install phase
    }); # end of excalidrawPackage
  in {
    # The built package, if anyone wants it directly
    packages.${system}.default = excalidrawPackage;

    # The NixOS module configs will use. i finally understand imports
    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.services.excalidraw = {
        enable = lib.mkEnableOption "Excalidraw self-hosted";
        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Port to serve Excalidraw on";
        }; # end of port
      }; # end of options

      config = lib.mkIf config.services.excalidraw.enable {
        services.nginx = {
          enable = true;
          virtualHosts."excalidraw" = {
            listen = [
              {
                addr = "0.0.0.0";
                port = config.services.excalidraw.port;
              }
            ]; # end of listen
            root = excalidrawPackage;
            locations."/" = {
              tryFiles = "$uri $uri/ /index.html";
            }; # end of locations
          }; # ebd of virtual hosts
        }; # end of services
        networking.firewall.allowedTCPPorts = [config.services.excalidraw.port];
      }; # end of config
    }; # end of nixosModules
  }; # end of let in
}
# haha nice

