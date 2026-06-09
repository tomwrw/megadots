{ den, ... }:
{
  den.aspects.syncthing =
    { host, ... }:
    {
      nixos =
        { ... }:
        {
          networking.firewall.allowedTCPPorts = [ 22000 ];
          networking.firewall.allowedUDPPorts = [
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
                relaysEnabled = false; # no relay servers
                globalAnnounceEnabled = false; # no global discovery
                localAnnounceEnabled = true; # LAN discovery only
                natEnabled = false; # local network, no NAT traversal
                urAccepted = -1; # disable usage-reporting prompts
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
