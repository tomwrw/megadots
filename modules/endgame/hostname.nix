{
  configurations.nixos.endgame.module = {
    networking.hostName = "endgame";
    networking.domain = "home.arpa";
  };
}
