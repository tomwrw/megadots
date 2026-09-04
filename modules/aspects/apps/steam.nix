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

  # Steam, including Proton and a persisted game library.
  den.aspects.steam = {
    includes = [
      (den.batteries.unfree [
        "steam"
        "steam-unwrapped"
      ])
      # Same trade as the kernel in core/linux-kernel.nix: trust nyx's cache
      # rather than build a 1.6 GiB Proton closure here.
      den.aspects.nyx-cache
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

        environment.systemPackages = [ pkgs.game-devices-udev-rules ];
      };

    # Included at host scope by roles/gaming.nix, but persist.home is read in a
    # user scope - so this takes the provides.to-users route or it lands in the
    # host pool where nothing reads it.
    provides.to-users.persist.home.directories = [
      ".steam"
      ".local/share/Steam"
    ];
  };
}
