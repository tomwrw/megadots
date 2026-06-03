{ den, inputs, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";

  den.aspects.flatmate = {
    includes = [
      den.aspects.base
      den.aspects.fonts
      den.aspects.gnome
      den.aspects.preservation
    ];

    nixos =
      { ... }:
      {
        imports = [
          # Surface Pro 7 hardware support (Intel GPU/display, Surface
          # Aggregator Module, touch). Without it the GPU hangs early in boot.
          # The cachyos kernel aspect mkForce-overrides the kernel this sets.
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
          ./_disko.nix
          ./_hardware.nix
        ];
        networking.hostName = "flatmate";
        system.stateVersion = "26.05";
      };
  };
}
