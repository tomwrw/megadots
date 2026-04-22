{
  flake.modules.nixos.flatmate = {
    networking.hostName = "flatmate";
    networking.domain = "home.arpa";
  };
}
