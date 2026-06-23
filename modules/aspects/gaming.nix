_: {
  den.aspects.gaming = {
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

        services.sunshine = {
          enable = true;
          autoStart = true;
          # DRM/KMS capture needs CAP_SYS_ADMIN on GNOME Wayland. Sunshine
          # master has XDG-portal/PipeWire capture that drops the setcap
          # requirement (LizardByte/Sunshine#4417, merged 2026-02), but no
          # packaged release contains it yet (nixpkgs ships 2025.924).
          # TODO: set capSysAdmin = false once nixpkgs ships a release with
          # portal capture.
          capSysAdmin = true;
          openFirewall = true;
          settings = {
            origin_web_ui_allowed = "lan";
          };
        };

        environment.systemPackages = [ pkgs.game-devices-udev-rules ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mangohud
        ];
      };
  };
}
