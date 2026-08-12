{
  den,
  config,
  lib,
  ...
}:
{
  # Peers this config doesn't build, set next to the roster in hosts.nix. Each
  # one becomes an extra entry appended to the pipe below, which is how a
  # TrueNAS box joins the mesh without pretending to be a den host.
  #
  # An option, and deliberately not under megadots.*: that prefix is aliased to
  # the published aspect namespace (modules/namespace.nix), so a setting put
  # there is silently absorbed and exported as if it were an aspect.
  #
  # Not the flake.externalPeers output this started as either.
  # Reading roster data back out of config.flake from a policy is a fixpoint
  # loop: the policy shapes den.schema.host, which shapes every host, which is
  # what flake.nixosConfigurations is - so forcing config.flake to answer one
  # question needs the answer first. Infinite recursion, and the trace points
  # at nixpkgs' module system rather than at anything written here. flake.* is
  # an output surface; nothing this config computes with should come back
  # through it.
  options.fleet.externalPeers = lib.mkOption {
    default = { };
    description = "Syncthing peers outside the den fleet, keyed by device name.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "The peer's Syncthing device ID.";
          };
          addresses = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              Explicit addresses, for a peer local discovery can't find. Left
              empty, Syncthing falls back to its own "dynamic" default.
            '';
          };
        };
      }
    );
  };

  config = {
    # Every host announces itself into the fleet-wide 'syncthing-peer' pool.
    # The quirk itself is declared in quirks.nix with the rest of them.
    #
    # Filtered here rather than downstream: a host that has opted out emits
    # nothing at all, so there is no "disabled" record travelling the pipe for
    # a consumer to remember to drop.
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

    # On the schema rather than named by each host. A machine that forgot to
    # include this would drop out of every other machine's device list and
    # quietly stop syncing - no error, and nothing in the diff to notice. The
    # schema makes it automatic, and checks.nix counts the result, so a
    # regression here is a failed check rather than a week of missing files.
    den.schema.host.includes = [ den.aspects.fleet.syncthing-peer ];

    # The consuming half. apps/sync/syncthing.nix includes this policy, so the
    # pipe is bound at the *user* scope where that aspect actually lands.
    #
    # collectAll rather than collect: collect only reaches sibling scopes under
    # a shared parent, and the hosts are siblings of each other, not of a user.
    #
    # The predicate names 'host' and nothing else, and that is load-bearing
    # even though the body ignores it. den reads the predicate's formal
    # argument names to filter by entity kind: a scope whose own kind isn't
    # among them is skipped, so this reads every host in the fleet and no
    # users. Simplifying it to (_: true) - which every linter will offer to do,
    # since the argument really is unused - names no kinds at all and matches
    # nothing. Leave it alone; checks.nix counts the devices to catch it.
    #
    # den also drops the collecting scope itself, but that's a user scope here,
    # so the host this user sits on is still in its own device list, which is
    # what Syncthing wants: it names itself among its folder's devices.
    #
    # Deliberately not on den.schema.user.includes. That would bind this pipe
    # for every user in the fleet, including ones that never run Syncthing, and
    # the pool would arrive at homes with nothing to do with it.
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
              # Only when set, so an external peer without explicit addresses
              # gets Syncthing's "dynamic" default rather than an empty list.
              // lib.optionalAttrs (peer.addresses != [ ]) { inherit (peer) addresses; }
            )
          ) config.fleet.externalPeers
        ))
      ];
  };
}
