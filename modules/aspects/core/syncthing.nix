{ den, ... }:
{
  den.aspects.core.syncthing =
    { host, ... }:
    {
      nixos = _: {
        networking.firewall.interfaces.${host.network.lanInterface} = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            22000
            21027
          ];
        };
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
        };
    };
}
