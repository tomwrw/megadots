{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../../secrets/${config.networking.hostName}.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    age.generateKey = false;
  };
}
