{
  flake.modules.nixos.spectre = {
    networking.hostName = "spectre";
    networking.domain = "home.arpa";
  };
}
