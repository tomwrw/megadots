{ den, ... }:
{
  megadots.apps.sync.syncthing = {
    description = "Syncthing, wired to whatever device mesh the syncthing-peer pipe hands it. Knows no fleet of its own.";

    # Binds the 'syncthing-peer' pool at this aspect's scope. Without it the
    # quirk argument below resolves to an empty list and every machine ends
    # up alone in its own mesh, which is valid config that syncs nothing.
    includes = [ den.policies.syncthing-mesh ];

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

    # The synced tree is real data and has to survive the rollback. The state
    # dir is just the index database, so losing that costs a rescan rather
    # than data, but that's slow on a big folder.
    home-persist.directories = [
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
        # The whole mesh, fleet hosts and external peers alike, already
        # gathered by den.policies.syncthing-mesh. This used to be a fold over
        # den.hosts with a '//' that could drop a host sharing a name across
        # two 'system' values, plus a unionOfDisjoint to stop my NAS shadowing
        # a machine. Collecting the records one per producer means neither
        # case can arise: a name is only ever written down once.
        #
        # A duplicate would now be a silent overwrite rather than an eval
        # error, so checks.nix counts the devices against the roster instead.
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
