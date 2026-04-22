{inputs, ...}: {
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

  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
  '';

  systems = [
    "x86_64-linux"
  ];
}
