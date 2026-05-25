{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.home.spec = {
    hostName = mkOption {
      type = types.str;
      description = ''
        Hostname of the machine this Home Manager configuration is
        deployed to. Used by modules that need host-aware behaviour
        (e.g. syncthing secret paths) without reaching into `osConfig`,
        so it works under both NixOS-integrated and standalone HM.
      '';
      example = "endgame";
    };

    domainName = mkOption {
      type = types.str;
      default = "home.arpa";
      description = ''
        DNS suffix for the local network. Combined with `hostName`
        for direct peer addressing (e.g. Syncthing device addresses).
      '';
      example = "home.arpa";
    };

    platform = mkOption {
      type = types.enum [
        "nixos"
        "standalone"
      ];
      description = ''
        Whether Home Manager is activated as a NixOS module (`nixos`)
        or as standalone Home Manager on a foreign distro (`standalone`,
        e.g. Arch). Used to gate modules and options that only make
        sense under one of the two activation modes.
      '';
    };
  };
}
