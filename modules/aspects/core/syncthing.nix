{ den, ... }:
{
  den.aspects.core.syncthing =
    { host, ... }:
    {
      # 22000 is sync traffic, 21027 is local discovery. LAN only, since I've
      # turned off relays and global announce below.
      #
      # This aspect comes in at user scope, so these ports only reach
      # core.networking because den.policies.firewall exposes the quirk
      # upward. Without that policy they just vanish.
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
          # '//' would drop a host that shared a name across two 'system'
          # values. Only theoretical while everything I own is x86_64.
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

          # The synced tree is real data and has to survive the rollback. The
          # state dir is just the index database, so losing that costs a
          # rescan rather than data, but that's slow on a big folder.
          home.persistence."/persist".directories = [
            "Syncthing"
            ".local/state/syncthing"
          ];
        };
    };
}
