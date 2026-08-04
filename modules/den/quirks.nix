{ den, ... }:
{
  den.quirks.unfree = {
    description = "Unfree package names (lib.getName) an aspect requires";
  };

  den.policies.unfree =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "unfree" [ pipe.expose ]) ];

  den.quirks.persist = {
    description = "Extra paths to persist at /persist: { directories, files }";
  };

  den.policies.persist =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "persist" [ pipe.expose ]) ];

  # Every quirk consumed at host scope needs an expose policy registered here,
  # or the same quirk emitted from a USER-scope aspect is silently discarded -
  # no error, no warning, just missing config. All current 'persist' producers
  # happen to be host-scope, so adding this changes nothing today; it exists so
  # that persisting a path from an app aspect (which are all user-scope) works
  # the first time rather than failing mysteriously.
  den.quirks.firewall = {
    description = ''
      LAN-scoped firewall ports an aspect needs: { tcp = [ ... ]; udp = [ ... ]; }.
      Aggregated by core.networking onto host.network.lanInterface.

      There is deliberately no per-entry interface or "global" escape hatch:
      LAN-scoping is the invariant this quirk exists to encode. Aspects must
      never set networking.firewall.* directly, nor a module's own
      openFirewall option, which opens the port on every interface.
    '';
  };

  den.policies.firewall =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "firewall" [ pipe.expose ]) ];

  # Every quirk consumed at host scope needs an expose policy registered here,
  # or the same quirk emitted from a USER-scope aspect is silently discarded -
  # no error, no warning, just missing config. All current 'persist' producers
  # happen to be host-scope, so adding that one changes nothing today; it exists
  # so persisting a path from an app aspect (which are all user-scope) works the
  # first time rather than failing mysteriously. 'firewall' genuinely needs it:
  # core.syncthing is included from the user aspect and opens ports 22000/21027.
  den.schema.user.includes = [
    den.policies.unfree
    den.policies.persist
    den.policies.firewall
  ];
}
