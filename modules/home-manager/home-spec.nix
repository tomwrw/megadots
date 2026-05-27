{
  lib,
  osConfig ? null,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.home.spec = {
    hostName = mkOption {
      type = types.str;
      default =
        if osConfig != null then
          osConfig.networking.hostName
        else
          throw "home.spec.hostName must be set explicitly under standalone Home Manager.";
      defaultText = lib.literalExpression "osConfig.networking.hostName";
      description = ''
        Hostname of the machine this Home Manager configuration is
        deployed to. Defaults to `osConfig.networking.hostName` when
        Home Manager is integrated as a NixOS module, eliminating
        drift between the two. Must be set explicitly under standalone
        Home Manager (where `osConfig` is unavailable).
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
