{ inputs, ... }:
{
  # nix-stable moves only on a release tag CI has already published to the
  # cache. No inputs.nixpkgs.follows, deliberately: every punktfunk store path is
  # keyed on punktfunk's own nixpkgs, so following mine would make all of them
  # miss the cache - the web console and plugin runner included, which are the
  # parts that hit it today.
  flake-file.inputs.punktfunk.url = "git+https://git.unom.io/unom/punktfunk?ref=nix-stable";

  # The Punktfunk streaming host, running alongside Sunshine rather than instead
  # of it. A host-scope app like apps/sunshine.nix.
  den.aspects.punktfunk = {
    nixos =
      { host, lib, ... }:
      {
        imports = [ inputs.punktfunk.nixosModules.default ];

        # Checked against https://nix.unom.io/punktfunk-cache.pub, which upstream
        # names as the source of truth. Only punktfunk's own paths live there.
        #
        # The host and gamescope still build locally: the module builds them from
        # this system's nixpkgs so they can load its Mesa, and the cache only holds
        # them for punktfunk's pinned nixpkgs. Expect a long rebuild after a
        # nixpkgs bump.
        nix.settings = {
          substituters = [ "https://nix.unom.io" ];
          trusted-public-keys = [ "punktfunk-cache-1:yhOJmHxzg6tzXpxSFzlYn6Pc6r0jHprsWqt8MZC654o=" ];
        };

        services.punktfunk.host = {
          enable = true;

          # Taken from the host's user list so no name appears here. This does
          # two jobs: the input/punktfunk group membership the virtual gamepads
          # need, and a ConditionUser on every user unit. The second keeps the
          # host out of root's and GDM's user managers - the greeter crash
          # Sunshine needed its own fix for.
          users = lib.attrNames host.users;

          # Restart with the GNOME session. Without it, a re-login leaves the host
          # holding a dead Wayland socket and portal connection, still answering
          # but failing every capture.
          desktopSession = true;

          # The default, stated because it is the expensive choice: a patched
          # gamescope compiled from source, for HDR10 off gamescope sessions.
          gamescopeHdr = true;

          # 47990 is Sunshine's web UI as well as punktfunk's management API, and
          # with gamestream off (the default) it is the only port the two share.
          # Clients learn the moved port from discovery, and the web console reads
          # it from ~/.config/punktfunk/mgmt-endpoint.
          settings.PUNKTFUNK_MGMT_BIND = "0.0.0.0:47991";

          # openFirewall stays off - the firewall quirk below scopes the ports to
          # the LAN instead.
        };

        # Defaults to host.autoStart, which is off because desktopSession is what
        # starts the host. Left alone, the console - where pairing happens - would
        # never start. The plugin runner already starts by default.
        services.punktfunk.web.autoStart = true;
      };

    # Identity certs, the mgmt token, the console password, paired clients and
    # plugins. A user service, so it lives in the home; host scope, so it takes
    # the provides.to-users route like apps/sunshine.nix.
    provides.to-users.persist.home.directories = [ ".config/punktfunk" ];

    # The native punktfunk/1 ports plus the console. The media stream is an
    # ephemeral UDP port the host hole-punches, so nothing fixed to open for it.
    firewall = {
      tcp = [
        47991 # management API, moved off Sunshine's 47990
        47992 # web console
        47993 # the console's plugin UIs, served from their own origin
      ];
      udp = [
        9777 # QUIC control plane
        9778 # browser streaming
        5353 # mDNS discovery
      ];
    };
  };
}
