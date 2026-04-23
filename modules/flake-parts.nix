{ inputs, ... }:
{
  flake-file.inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-file.url = "github:vic/flake-file";
    import-tree.url = "github:vic/import-tree";
  };

  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.flake-file.flakeModules.default
  ];

  flake-file.description = "megadots - a Dendritic NixOS and Home Manager configuration by tomwrw.";

  flake-file.outputs = "dendritic";

  flake-file.nixConfig = {
    abort-on-warn = true;
  };

  systems = [
    "x86_64-linux"
  ];
}
