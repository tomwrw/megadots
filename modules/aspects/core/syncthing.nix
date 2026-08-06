{ den, ... }:
{
  den.aspects.core.syncthing =
    { host, ... }:
    {
      # 22000 is sync traffic (TCP + QUIC), 21027 is local discovery. LAN-only
      # by construction: relays and global announce are disabled below.
      #
      # This aspect is included at USER scope, so these ports only reach
      # core.networking because den.policies.firewall exposes the quirk upward
      # (modules/den/quirks.nix). Without that policy they vanish silently.
      firewall = {
        tcp = [ 22000 ];
        udp = [
          22000
          21027
        ];
      };

      homeManager =
        {
          config,
          lib,
          ...
        }:
        let
          # '//' would silently drop same-named hosts across two different
          # 'system' values (e.g. a same-named host added under
          # aarch64-linux) - purely theoretical with only x86_64-linux in
          # the fleet today.
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
            key = config.sops.secrets."syncthing/${host.name}/key".path;
            cert = config.sops.secrets."syncthing/${host.name}/cert".path;
            guiCredentials = {
              username = "admin";
              passwordFile = config.sops.secrets."syncthing/${host.name}/guiPassword".path;
            };
            overrideDevices = true;
            overrideFolders = true;
            settings = {
              devices = lib.mapAttrs (_: h: { id = h.syncthing.id; }) meshHosts;
              options = {
                relaysEnabled = false;
                globalAnnounceEnabled = false;
                localAnnounceEnabled = true;
                natEnabled = false;
                urAccepted = -1;
              };

              folders.Syncthing = {
                path = "${config.home.homeDirectory}/Syncthing";
                devices = builtins.attrNames meshHosts;
                versioning = {
                  type = "staggered";
                  params = {
                    cleanInterval = "3600";
                    maxAge = "2592000";
                  };
                };
              };
            };
          };

          # The replicated tree is real user data and has to outlive the boot
          # rollback. The state directory holds the index database: key and cert
          # come from sops and devices/folders are overridden declaratively, so
          # losing that costs a full rescan and re-index rather than data - but
          # on a large folder that is not cheap.
          home.persistence."/persist".directories = [
            "Syncthing"
            ".local/state/syncthing"
          ];
        };
    };
}
