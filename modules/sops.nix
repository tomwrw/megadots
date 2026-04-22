{inputs, ...}: {
  flake-file.inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.base = {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      age.generateKey = false;
    };
  };
}
