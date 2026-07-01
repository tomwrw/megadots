{
  # For those who come after...
  description = "nix-config - a NixOS and Home Manager configuration by tomwrw.";
  # Define all the flake inputs (dependencies) for the configuration.
  inputs = {
    # Nixpkgs is the primary source of packages. It is set to the
    # unstable channel by default. https://nixpkgs-tracker.ocfox.me
    # can be used to check PR status for packages.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # A stable version of Nixpkgs for specific packages.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    # Common hardware definitions for NixOS.
    hardware.url = "github:nixos/nixos-hardware";
    # A list of available Nix systems, including Linux and Darwin.
    # Supports: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
    systems.url = "github:nix-systems/default";
    # Manages impermanent file system configurations.
    impermanence.url = "github:nix-community/impermanence";
    # Home Manager is used to manage user-specific configurations
    # and dotfiles.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secure Boot for NixOS.
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Input for sops-nix secrets management.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # CachyOS kernel images.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    # A Nix module for declarative disk partitioning.
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Provides Firefox extensions as Nix packages.
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # A Nix flake for customising the Spotify client with Spicetify.
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Theme engine stylix for custom colours and themeing.
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      systems,
      ...
    }@inputs:
    let
      # Inherit outputs from the current flake.
      inherit (self) outputs;
      # Combine the Nixpkgs and Home Manager libraries for
      # unified function access.
      lib = nixpkgs.lib // home-manager.lib;
      # Import the list of supported systems from the systems input.
      # Includes: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
      allSystems = import systems;
      # A set of Nixpkgs packages for each supported system.
      # Uses the systems input for explicit cross-platform support.
      pkgsFor = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system});
      # A helper function to apply a function across all supported systems.
      forEachSystem = f: lib.genAttrs allSystems (system: f pkgsFor.${system});
    in
    {
      inherit lib;
      # Expose custom NixOS modules for the configuration.
      nixosModules = import ./modules/nixos;
      # Expose custom Home Manager modules for user configurations.
      homeModules = import ./modules/home-manager;
      # Expose custom packages as overlays.
      overlays = import ./overlays { inherit inputs outputs; };
      # Build custom packages from the local pkgs directory.
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      # Specify the Nix file formatter to be used by nix fmt.
      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);
      # Define flake checks to validate the configuration.
      # Run with: nix flake check.
      checks = forEachSystem (pkgs: {
        # Verify all Nix files are properly formatted.
        formatting = pkgs.runCommand "check-formatting" { } ''
          cd ${./.}
          ${pkgs.nixfmt}/bin/nixfmt --check . 2>&1 || {
            echo "Run 'nix fmt' to fix formatting issues"
            exit 1
          }
          touch $out
        '';
        # Find dead code and unused variables.
        deadnix = pkgs.runCommand "check-deadnix" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${./.}
          touch $out
        '';
        # Lint for common Nix anti-patterns.
        statix = pkgs.runCommand "check-statix" { } ''
          ${pkgs.statix}/bin/statix check ${./.}
          touch $out
        '';
      });
      # Define a development shell with specific tools
      # for working on the flake, such as nixfmt
      # for formatting and git for version control.
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [
            # Packages to include in devShell.
            pkgs.nixfmt-tree
            pkgs.deadnix
            pkgs.git
            pkgs.statix
          ];
        };
      });
      # Define system configurations for each host.
      nixosConfigurations = {
        # The configuration for my main rig
        # used for most things named 'endgame'.
        endgame = lib.nixosSystem {
          modules = [
            ./hosts/nixos/endgame
          ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
        # The configuration for my mobile
        # workstation, named 'flatmate'.
        flatmate = lib.nixosSystem {
          modules = [
            ./hosts/nixos/flatmate
          ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
        # The configuration for a virtual machine
        # used for testing, named 'spectre'.
        spectre = lib.nixosSystem {
          modules = [
            ./hosts/nixos/spectre
          ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
      };
    };
}
