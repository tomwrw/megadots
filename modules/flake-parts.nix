{ inputs, ... }:
{
  flake-file = {
    inputs = {
      flake-parts.url = "github:hercules-ci/flake-parts";
      flake-file.url = "github:vic/flake-file";
      import-tree.url = "github:vic/import-tree";
    };
    description = "megadots - a Dendritic NixOS and Home Manager configuration by tomwrw.";
    outputs = "dendritic";
    do-not-edit = ''
      # DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
      # Use `nix run .#write-flake` to regenerate it.
      #
      # For those who come after...
    '';
    nixConfig = {
      abort-on-warn = true;
    };
  };

  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.flake-file.flakeModules.default
  ];

  systems = [
    "x86_64-linux"
  ];
}
