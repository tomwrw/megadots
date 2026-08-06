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
      # UNVERIFIED paths, but the consequence is unusually expensive: without
      # these, every boot re-downloads the entire library. Confirm with
      # `ls ~/.local/share ~/.steam` after first launch.
      #
      # This is also the one entry worth thinking about before deploying: the
      # library shares /persist with everything else, so the subvolume needs to
      # be sized for it.
      home.persistence."/persist".directories = [
        ".steam"
        ".local/share/Steam"
      ];
    };
  };
}
