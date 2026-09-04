{ den, ... }:
{
  # Syncthing, wired to whatever device mesh the syncthing-peer pipe hands it.
  # Knows no fleet of its own.
  den.aspects.syncthing = {
    # Binds the pool at this aspect.s scope. Without it the quirk argument below
    # is an empty list and every machine ends up alone in its own mesh - valid
    # config that syncs nothing.
    includes = [ den.policies.syncthing-mesh ];

    # 22000 is sync traffic, 21027 local discovery. LAN only, since relays and
    # global announce are off below. This aspect comes in at user scope, so the
    # ports reach core/networking only through den.policies.firewall.
    firewall = {
      tcp = [ 22000 ];
      udp = [
        22000
        21027
      ];
    };

    # The synced tree is real data and has to survive the rollback. The state
    # dir is just the index database, so losing that costs a rescan rather
    # than data, but that's slow on a big folder.
    persist.home.directories = [
      "Syncthing"
      ".local/state/syncthing"
    ];

    homeManager =
      {
        host,
        syncthing-peer,
        config,
        lib,
        ...
      }:
      let
        # The whole mesh, fleet hosts and external peers alike, already gathered
        # by den.policies.syncthing-mesh. One record per producer, so a name is
        # only ever written down once.
        allDevices = lib.listToAttrs (
          map (p: lib.nameValuePair p.name (removeAttrs p [ "name" ])) syncthing-peer
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
            devices = allDevices;
            options = {
              relaysEnabled = false;
              globalAnnounceEnabled = false;
              localAnnounceEnabled = true;
              natEnabled = false;
              urAccepted = -1;
            };

            folders.Syncthing = {
              path = "${config.home.homeDirectory}/Syncthing";
              devices = builtins.attrNames allDevices;
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

      };
  };
}
