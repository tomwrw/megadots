{
  config,
  lib,
  ...
}:
let
  # Read host identity from the home-spec, so this module works under
  # both NixOS-integrated and standalone Home Manager.
  currentHost = config.home.spec.hostName;
  domain = config.home.spec.domainName;
  # Define my Syncthing hosts with thier Syncthing ID.
  hostIdentifiers = {
    endgame = "O5ZE76L-VFVTOEB-LBIKRRS-LNJKJTN-SOPSNTS-NMTNUHO-OOO453I-PXDOBAI";
    flatmate = "PSSB5YD-TVF4BXM-RH4E5DY-NZYON6Y-LKBBBGL-HHNIB2T-K6QRHIM-FTHKUAF";
    spectre = "IV2MEMD-PDQR3JJ-SNL2QMY-52YXR5X-GM227G6-DTRMJLF-HRW6CA6-VZQ74AG";
  };
  # Helper to get the list of hostnames as
  # [ "endgame" "flatmate" "spectre" ].
  allHosts = builtins.attrNames hostIdentifiers;
in
{
  sops.secrets = {
    "hosts/${currentHost}/syncthing/key" = { };
    "hosts/${currentHost}/syncthing/cert" = { };
    "hosts/${currentHost}/syncthing/guiPassword" = { };
  };
  # Configure the Syncthing service.
  services.syncthing = {
    enable = true;
    # Key and Cert prevents the need to accept sharing
    # with devices in my config. They are stored in the
    # secrets file.
    key = config.sops.secrets."hosts/${currentHost}/syncthing/key".path;
    cert = config.sops.secrets."hosts/${currentHost}/syncthing/cert".path;
    # The password file is used for the GUI password.
    # Also stored in the secrets file.
    guiCredentials = {
      username = "admin";
      passwordFile = config.sops.secrets."hosts/${currentHost}/syncthing/guiPassword".path;
    };
    settings = {
      # Syncthing kicks up a stink if partial config is
      # already present on a device, so these options force
      # override. This was presenting as a device not reading
      # it's secrets properly and asking for user to accept
      # device sharing, exactly what keys and certs are
      # designed to avoid.
      overrideDevices = true;
      overrideFolders = true;
      # Dial peers directly by FQDN. Local announce can't reach across
      # L2 boundaries (e.g. libvirt bridge ↔ LAN), and global discovery
      # and relays are disabled below.
      devices = lib.mapAttrs (host: id: {
        inherit id;
        addresses = [ "tcp://${host}.${domain}:22000" ];
      }) hostIdentifiers;
      # Specify additional options for Syncthing here.
      options = {
        # Keep traffic local and disable external relay/discovery.
        relaysEnabled = false; # Don't use relay servers.
        globalAnnounceEnabled = false; # Don't announce to global discovery.
        localAnnounceEnabled = true; # Keep local/LAN discovery.
        natEnabled = false; # No NAT traversal needed on local network.
        urAcceptedStr = "-1"; # Disable usage reporting prompts.
      };
      # Syncthing folder definitions go here.
      folders = {
        # Sync - my primary sync folder on all hosts.
        "Syncthing" = {
          path = "${config.home.homeDirectory}/Documents/Syncthing";
          # Use the list of all keys from the hostIdentifiers map.
          devices = allHosts;
          # File versioning to keep deleted/modified file history.
          versioning = {
            type = "staggered";
            params = {
              # Check for old versions every hour.
              cleanInterval = "3600";
              # Keep versions for 30 days (in seconds).
              maxAge = "2592000";
            };
          };
        };
      };
    };
  };
}
