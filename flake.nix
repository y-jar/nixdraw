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

    excalidrawPackage = pkgs.mkYarnPackage {
      name = "excalidraw";
      src = ./.;
      yarnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAA";
      buildPhase = ''
        export HOME=$TMPDIR
        yarn --offline build
      ''; # end of build phase
      installPhase = ''
        mkdir -p $out
        cp -r deps/excalidraw/build/* $out/
      ''; # installPhase
      distPhase = "true";
    }; # end of excalidrawPackage
  in {
    # The built package, if anyone wants it directly
    packages.${system}.default = excalidrawPackage;

    # The NixOS module — this is what your system flake will use
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
        };
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

