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

    # Steam's state is user-owned, but this aspect is included at HOST scope
    # (roles/gaming.nix), and a bare homeManager key on a host-scope aspect is
    # silently dropped by den. provides.to-users is the delivery path that
    # actually reaches the user.
    provides.to-users.homeManager = _: {
      home.persistence."/persist".directories = [
        ".steam"
        ".local/share/Steam"
      ];
    };
  };
}
