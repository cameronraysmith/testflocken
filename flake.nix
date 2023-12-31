{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    flocken = {
      url = "github:mirkolenz/flocken/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    systems,
    flocken,
    poetry2nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      perSystem = {
        pkgs,
        system,
        lib,
        self',
        ...
      }: let
        python = pkgs.python311;
        poetry = pkgs.poetry;
        poetryAppArgs = {
          inherit python;
          projectDir = ./.;
          preferWheels = true;
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [poetry2nix.overlays.default];
        };
        overlayAttrs = {
          inherit (self'.packages) testflocken;
        };
        packages = {
          default = pkgs.poetry2nix.mkPoetryApplication (
            poetryAppArgs
            // {
              checkPhase = "pytest";
            }
          );
          testflocken = self'.packages.default;
          docker = pkgs.dockerTools.buildLayeredImage {
            name = "testflocken";
            tag = "latest";
            created = "now";
            config = {
              entrypoint = [];
              cmd = [(lib.getExe self'.packages.default)];
            };
          };
          releaseEnv = pkgs.buildEnv {
            name = "release-env";
            paths = [poetry python];
          };
        };
        legacyPackages.dockerManifest = flocken.legacyPackages.${system}.mkDockerManifest {
          github = {
            enable = true;
            token = builtins.getEnv "GH_TOKEN";
          };
          version = builtins.getEnv "VERSION";
          images = with self.packages; [x86_64-linux.docker aarch64-linux.docker];
        };
        devShells.default = pkgs.mkShell {
          packages = [poetry python pkgs.vhs];
          POETRY_VIRTUALENVS_IN_PROJECT = true;
          shellHook = ''
            ${lib.getExe poetry} env use ${lib.getExe python}
            ${lib.getExe poetry} install --sync --all-extras --no-root
          '';
        };
      };
    };
}
