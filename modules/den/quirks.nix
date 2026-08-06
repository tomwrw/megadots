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

  den.quirks.firewall = {
    description = ''
      LAN-scoped firewall ports an aspect needs: { tcp = [ ... ]; udp = [ ... ]; }.
      Aggregated by core.networking onto host.network.lanInterface.

      There is no per-entry interface and no "global" escape hatch, because
      LAN-only is the whole point of this quirk. Aspects should never set
      networking.firewall.* themselves, or a module's own openFirewall option,
      which opens the port on every interface.
    '';
  };

  den.policies.firewall =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "firewall" [ pipe.expose ]) ];

  # Any quirk I consume at host scope needs an expose policy here, or the same
  # quirk coming from a user-scope aspect just vanishes. No error, no warning,
  # just missing config. All the 'persist' producers are host-scope today so
  # that one changes nothing yet, it's there so persisting from an app aspect
  # works first time. 'firewall' really does need it, since core.syncthing
  # comes in from the user aspect and opens 22000 and 21027.
  den.schema.user.includes = [
    den.policies.unfree
    den.policies.persist
    den.policies.firewall
  ];
}
