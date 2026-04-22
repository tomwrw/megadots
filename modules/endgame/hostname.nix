{
  flake.modules.nixos.endgame = {
    networking.hostName = "endgame";
    networking.domain = "home.arpa";
  };
}
