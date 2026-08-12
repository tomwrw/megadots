{ den, ... }:
{
  megadots.apps.gaming.steam = {
    description = "Steam, including Proton and a persisted game library.";

    includes = [
      (den.batteries.unfree [
        "steam"
        "steam-unwrapped"
      ])
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
    # host scope, and the home-persist quirk is only ever read in a user scope.
    # provides.to-users is the path that actually reaches my home - emitted
    # bare here it would land in the host's pool, which has no consumer.
    provides.to-users.home-persist.directories = [
      ".steam"
      ".local/share/Steam"
    ];
  };
}
