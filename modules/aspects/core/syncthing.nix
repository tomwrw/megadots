{ den, ... }:
let
  # Syncthing peers that this config doesn't build. They can't come from
  # den.hosts, which describes whole machines (disk, LAN interface, users) and
  # turns each entry into a nixosConfiguration. The TrueNAS box is just a
  # device ID to trust, and the other half of the pairing is done by hand in
  # its own Syncthing GUI.
  #
  # Addresses are pinned rather than left dynamic. Relays and global discovery
  # are off below, so the only thing that could locate a peer is a local
  # announce on 21027, and an appliance running Syncthing in a container often
  # can't broadcast onto the LAN at all. A static lease on the NAS makes this
  # the more reliable half of the trade anyway.
  externalPeers = {
    nas = {
      # TrueNAS Syncthing GUI: Actions > Show ID.
      id = "F7JXVJN-DXADY4D-OGQGPUG-ENDQEDW-5PROBMK-E37HIYE-6OJ4HKW-25W4YQX";
      addresses = [ "tcp://10.20.1.3:20978" ];
    };
  };
in
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

          meshDevices = lib.mapAttrs (_: h: { id = h.syncthing.id; }) meshHosts;

          # Everything this host peers with, mesh and external alike. Plain
          # '//' would let an external peer shadow a mesh host that shared its
          # name, and the only symptom would be a machine that quietly stops
          # syncing; unionOfDisjoint refuses instead.
          allDevices = lib.attrsets.unionOfDisjoint meshDevices externalPeers;
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
