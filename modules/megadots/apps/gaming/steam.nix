{ inputs, den, ... }:
{
  # CachyOS/proton-cachyos is a Proton source tree, not a flake, and building it
  # is hours of wine and mingw. chaotic-cx/nyx packages the same tree and caches
  # the result, so this input is really a route to their binary.
  #
  # Deliberately not following nixpkgs: chaotic builds against its own pin, and
  # overriding it invalidates every hash their cache is keyed on, which turns
  # this back into the source build the input exists to avoid.
  flake-file.inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

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
          # Both, not one: Proton-CachyOS carries the newer upstream base and
          # the CachyOS patches, GE-Proton the media codecs and per-game fixes
          # it has always carried. Steam picks per game, so the choice stays in
          # the game's properties rather than here.
          extraCompatPackages = [
            pkgs.proton-ge-bin
            # The generic build, not proton-cachyos_x86_64_v3. This aspect is
            # host-agnostic and a v3 binary is an illegal instruction away from
            # a crash on anything older than Haswell. Swap it per host if a
            # host ever wants the optimized one.
            inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos
          ];
        };
        programs.gamemode.enable = true;
        hardware.steam-hardware.enable = true;

        # Same trade as the CachyOS kernel in core/linux-kernel.nix: trust a
        # third-party cache rather than build a 1.6 GiB Proton closure here.
        nix.settings.substituters = [ "https://nyx-cache.chaotic.cx/" ];
        nix.settings.trusted-public-keys = [
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        ];

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
