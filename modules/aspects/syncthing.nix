# Syncthing as a Home Manager service, forming a private LAN mesh across hosts.
#
# The device mesh is built from the den.hosts roster: each host declares its own
# `syncthing.id` (modules/hosts.nix), and this aspect reads den.hosts to assemble
# the device list — no central device map. cert/key/guiPassword come from the
# user's sops scope (secrets/users/tomwrw.yaml), keyed per host, so device IDs
# are deterministic and peers auto-trust each other.
{ den, ... }:
{
  den.aspects.syncthing =
    { host, ... }:
    {
      homeManager =
        {
          config,
          lib,
          ...
        }:
        let
          # Flatten all systems' hosts into name -> hostCfg, keep mesh members.
          meshHosts = lib.filterAttrs (_: h: h.syncthing.enable && h.syncthing.id != "") (
            lib.foldl' (acc: sys: acc // den.hosts.${sys}) { } (builtins.attrNames den.hosts)
          );
        in
        {
          sops.secrets = {
            "syncthing/${host.name}/key" = { };
            "syncthing/${host.name}/cert" = { };
            "syncthing/${host.name}/guiPassword" = { };
          };

          services.syncthing = {
            enable = true;
            # Provisioned cert/key make the device ID deterministic and let peers
            # auto-trust without a manual "accept device" prompt.
            key = config.sops.secrets."syncthing/${host.name}/key".path;
            cert = config.sops.secrets."syncthing/${host.name}/cert".path;
            guiCredentials = {
              username = "admin";
              passwordFile = config.sops.secrets."syncthing/${host.name}/guiPassword".path;
            };
            # Keep Syncthing's on-disk config in lockstep with this declaration.
            overrideDevices = true;
            overrideFolders = true;
            settings = {
              # No static addresses: all hosts share a subnet, so local-announce
              # discovery connects peers by device ID (addresses default to dynamic).
              devices = lib.mapAttrs (_: h: { id = h.syncthing.id; }) meshHosts;

              options = {
                relaysEnabled = false; # no relay servers
                globalAnnounceEnabled = false; # no global discovery
                localAnnounceEnabled = true; # LAN discovery only
                natEnabled = false; # local network, no NAT traversal
                urAcceptedStr = "-1"; # disable usage-reporting prompts
              };

              folders.Syncthing = {
                path = "${config.home.homeDirectory}/Syncthing";
                devices = builtins.attrNames meshHosts;
                versioning = {
                  type = "staggered";
                  params = {
                    cleanInterval = "3600"; # prune hourly
                    maxAge = "2592000"; # keep versions 30 days
                  };
                };
              };
            };
          };
        };
    };
}
