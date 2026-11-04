{ den, ... }:
{
  # The Xbox Wireless dongle, driven by xone. Plugged into the machine that runs
  # the game, so a controller in the next room talks to it directly instead of
  # through the streaming client - PunktFunk then carries only picture and sound.
  den.aspects.xbox-wireless = {
    # The dongle's firmware is Microsoft's, fetched from Windows Update.
    includes = [ (den.batteries.unfree [ "xone-dongle-firmware" ]) ];

    # Also blacklists xpad (xone drives Xbox One/Series pads, wired too) and
    # mt76x2u.
    #
    # Nothing persisted: pairing lives on the dongle and the controller, not on
    # disk. xone is not in nixpkgs' or nyx's cache for the CachyOS kernel, so it
    # compiles locally after each kernel bump - a small module.
    nixos = {
      hardware.xone.enable = true;

      # xone turns xpad-noone on by default, to keep Xbox 360 pads working with
      # xpad blacklisted. Off, because it breaks the build: nixpkgs' module
      # aggregator now concatenates a <module>.ko.cer certificate for every
      # out-of-tree module, and xpad-noone's custom install ships none, so
      # assembling the kernel's module tree dies on a missing
      # xpad-noone.ko.cer. xone's own modules carry theirs. The cost is Xbox 360
      # controllers, which I do not use; turn it back on once nixpkgs fixes the
      # package.
      hardware.xpad-noone.enable = false;
    };
  };
}
