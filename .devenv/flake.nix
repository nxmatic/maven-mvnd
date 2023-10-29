{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    # Package sets
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Flake utilities
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";

    # nix maven repository
    mvn2nix.url = "github:fzakaria/mvn2nix";
  };

  outputs = { self, flake-utils, ... }@inputs:
    let
      inherit (self.lib) attrValues makeOverridable optionalAttrs singleton;

      nixpkgsDefaults = {
        config = {
          allowUnfree = true;
	        allowBroken = false;
        };
      };
    in {
      lib = inputs.nixpkgs-unstable.lib;

      overlays = {
        pkgs-master = _: prev: {
          pkgs-release = import inputs.nixpkgs-master {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-stable = _: prev: {
          pkgs-release = import inputs.nixpkgs-stable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-unstable = _: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-mvn2nix = _: prev: {
          pkgs-mvn2nix = import inputs.mvn2nix {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
      };

    } // flake-utils.lib.eachDefaultSystem (system: {

      stable-packages = import inputs.nixpkgs-stable (nixpkgsDefaults // { inherit system; });

      unstable-packages = import inputs.nixpkgs-unstable (nixpkgsDefaults // { inherit system; });

      mvn2nix-packages = import inputs.mvn2nix (nixpkgsDefaults // { inherit system; });

      devShells = let
        stable-pkgs = self.stable-packages.${system};
        unstable-pkgs = self.unstable-packages.${system};
        mvn2nix-pkgs = self.mvn2nix-packages.${system};
      in {
        default = stable-pkgs.mkShell {
          packages = [
            stable-pkgs.graalvm-ce
            mvn2nix-pkgs.mvn2nix
          ];
          shellHook = ''
            export SHELL=$(which zsh)
            exec zsh
          '';
        };

      };


    });

}
