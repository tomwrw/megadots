_: {
  den.aspects.apps.gaming.steam = {
    unfree = [
      "steam"
      "steam-unwrapped"
    ];

    nixos =
      { pkgs, ... }:
      {
        programs.steam = {
          enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
        programs.gamemode.enable = true;
        hardware.steam-hardware.enable = true;

        environment.systemPackages = [ pkgs.game-devices-udev-rules ];
      };

    # Steam's state belongs to me, but roles/gaming.nix includes this aspect at
    # host scope, and den drops a bare homeManager block there.
    # provides.to-users is the path that actually reaches my home.
    provides.to-users.homeManager = _: {
      home.persistence."/persist".directories = [
        ".steam"
        ".local/share/Steam"
      ];
    };
  };
}
