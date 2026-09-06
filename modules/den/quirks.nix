{
  den,
  config,
  lib,
  ...
}:
{
  # Every quirk this config has, and everything that routes one. A quirk is a
  # named channel an aspect writes to without knowing who reads it; a policy
  # decides where the data travels. One file, so there is never a second place
  # to look.
  #
  # No 'unfree' quirk: den.batteries.unfree does the same job and more, emitting
  # into the class being resolved *and* into the host's OS class, so an unfree
  # package declared by a user aspect is allowed on the host too.

  # State that has to survive the rollback, in two keys because the two halves
  # land in different option trees in different classes:
  #
  #   persist.system.directories = [ "/var/lib/fwupd" ];   -> environment.persistence
  #   persist.home.directories   = [ ".ssh" ];             -> home.persistence
  #
  # They cannot share one key. core.sops is included at host scope and at user
  # scope, so a single flat list would push ".config/sops/age" into
  # environment.persistence as though it were an absolute path. Naming the two
  # means each consumer reads its own and ignores the other.
  #
  # An aspect names only its own paths. Nothing here mentions impermanence or
  # /persist - core.impermanence is the only consumer, and it is what decides
  # the store exists at all.
  den.quirks.persist = {
    description = "Paths that survive the rollback: { system = { directories, files }; home = { directories, files }; }";
  };

  # Exposed so a user-scope aspect's system paths reach the host consumer.
  # Without this they are collected in the user scope and silently discarded.
  # Expose copies rather than moves, so the home entries an aspect emits in the
  # same breath are still readable where they are consumed.
  den.policies.persist =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "persist" [ pipe.expose ]) ];

  # LAN-scoped firewall ports: { tcp = [ ... ]; udp = [ ... ]; }, aggregated by
  # core.networking onto host.network.lanInterface.
  #
  # No per-entry interface and no global escape hatch, because LAN-only is the
  # whole point. An aspect should never set networking.firewall.* itself, or a
  # module's own openFirewall option, which opens the port everywhere.
  den.quirks.firewall = {
    description = "LAN-scoped firewall ports an aspect needs: { tcp = [ ... ]; udp = [ ... ]; }";
  };

  den.policies.firewall =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "firewall" [ pipe.expose ]) ];

  # The look, stated once by a user and read at both scopes: desktop.stylix
  # themes the Home Manager session and the host underneath it, and a NixOS
  # module cannot read a Home Manager option.
  den.quirks.theme = {
    description = ''The look: { scheme = "rose-pine-moon"; wallpaper = ./snake.png; }, optionally polarity'';
  };

  # The terminal to run a terminal program in, stated once by whichever terminal
  # aspect is installed and read by anything that needs to open a window around
  # a command - apps/neovim.nix, for its desktop entry.
  #
  # It carries a function of pkgs rather than a package, because "run this
  # command" is not spelled the same way twice: ghostty and alacritty take
  # "-e cmd", wezterm takes "start -- cmd", kitty takes the command bare. The
  # flag belongs with the terminal that understands it, not with every consumer.
  # Applied by the consumer inside a class block, where pkgs exists - the same
  # trick desktop/stylix.nix uses for its font set.
  #
  # Nothing here says which terminal. Swapping ghostty for alacritty is writing
  # this quirk from the new aspect and removing the old one from users/tomwrw;
  # no consumer changes.
  den.quirks.terminal = {
    description = ''How to run a command in a terminal window: { exec = pkgs: "\''${terminal} -e"; }'';
  };

  # One device in the mesh: { name = "endgame"; id = "O5ZE76L-..."; } and
  # optionally addresses for a peer local discovery can't find. Produced once
  # per host, consumed once per user, so it crosses both the fleet and the
  # scope boundary. The syncthing aspect just reads the pool it is handed and
  # knows nothing about which machines I own.
  den.quirks.syncthing-peer = {
    description = ''One device in the Syncthing mesh: { name = "endgame"; id = "O5ZE76L-..."; }'';
  };

  # Every host announces itself into the pool. Filtered here rather than
  # downstream, so a host that opted out emits nothing at all and there is no
  # disabled record travelling the pipe for a consumer to remember to drop.
  den.aspects.fleet.syncthing-peer =
    { host, ... }:
    lib.optionalAttrs (host.syncthing.enable && host.syncthing.id != "") {
      syncthing-peer = [
        {
          inherit (host) name;
          inherit (host.syncthing) id;
        }
      ];
    };

  # The consuming half, included by the syncthing aspect so the pipe binds at
  # the user scope where that aspect lands. Not on den.schema.user.includes,
  # which would bind it for users that never run Syncthing.
  #
  # collectAll rather than collect: collect only reaches siblings under a shared
  # parent, and the hosts are siblings of each other, not of a user.
  #
  # The predicate names 'host' and nothing else, and that is load-bearing even
  # though the body ignores it - den reads the formal argument names to filter
  # by entity kind. Simplifying it to (_: true), which every linter will offer,
  # names no kinds and matches nothing, and the mesh silently empties. The
  # deadnix exemption in flake/formatter.nix exists for this line.
  den.policies.syncthing-mesh =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [
      (pipe.from "syncthing-peer" (
        [ (pipe.collectAll ({ host, ... }: true)) ]
        ++ lib.mapAttrsToList (
          name: peer:
          pipe.append (
            {
              inherit name;
            }
            // {
              inherit (peer) id;
            }
            # Only when set, so a peer without explicit addresses gets
            # Syncthing's "dynamic" default rather than an empty list.
            // lib.optionalAttrs (peer.addresses != [ ]) { inherit (peer) addresses; }
          )
        ) config.fleet.externalPeers
      ))
    ];

  # A host that forgot to announce itself would drop out of every other
  # machine's device list and quietly stop syncing, so the schema does it rather
  # than each host naming it.
  den.schema.host.includes = [ den.aspects.fleet.syncthing-peer ];

  # Quirks a user-scope aspect emits but a host-scope aspect consumes. Without
  # these the data is collected in the user scope and dropped with no error.
  den.schema.user.includes = [
    den.policies.persist
    den.policies.firewall
  ];
}
