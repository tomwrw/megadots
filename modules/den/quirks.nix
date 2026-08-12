{ den, ... }:
{
  # No 'unfree' quirk here. den.batteries.unfree does the same job and more:
  # it emits into the class being resolved *and* into the host's OS class when
  # that class is homeManager, so an unfree package declared by a user aspect
  # is allowed on the host too. The hand-rolled version only ever wrote a nixos
  # block, which worked solely because home-manager.useGlobalPkgs makes Home
  # Manager borrow the host's pkgs - and so would never have worked for a
  # standalone home. den's predicate builder is in den.default already, so
  # keeping a second definition of nixpkgs.config.allowUnfreePredicate here
  # would have been a straight eval conflict the moment either one had data.

  den.quirks.persist = {
    description = "Extra paths to persist at /persist: { directories, files }";
  };

  den.policies.persist =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "persist" [ pipe.expose ]) ];

  den.quirks.home-persist = {
    description = ''
      Home-relative paths a user aspect needs to survive the rollback:
        { directories = [ ".config/Signal" ]; files = [ ".ssh/known_hosts" ]; }

      Deliberately not the same quirk as 'persist'. That one carries absolute
      system paths and is consumed on the host; these are relative to $HOME and
      are consumed inside the user's Home Manager evaluation. One shared name
      would mean an aspect included at both scopes - core.sops is - pushing
      ".config/sops/age/keys.txt" into environment.persistence as if it were an
      absolute path.

      There is no policy for this quirk, and that is the point. Producer and
      consumer are both in the user scope, so nothing needs to travel: an
      expose policy would push the pool up to the host, where the paths are
      meaningless. It also means an app aspect never names impermanence or
      /persist, so the same aspect evaluates in a standalone den.homes where
      no consumer exists and the pool is simply never read.
    '';
  };

  den.quirks.persist-store = {
    description = ''
      Announces that a persistent store exists, and where: { root = "/persist"; }

      A capability, not data. It lets an aspect that has to do its own copying
      - desktop.gnome and monitors.xml - find the store without hardcoding the
      path or importing impermanence. An empty pool means no store, which is
      the signal to emit nothing at all rather than units that fail every boot.
    '';
  };

  den.quirks.seed = {
    description = ''
      Files 'just deploy' writes into /persist/home/<user> before the machine
      has ever booted, home-relative and tagged with their owner:

        seed = { user, ... }: { owner = user.userName; files = [ ".ssh/id_ed25519" ]; };

      A function on purpose. The producers are user-scope aspects, but the
      consumer is host scope - tmpfiles rules and a chown unit are NixOS config
      - so this pool travels up through pipe.expose, and a flat list of paths
      would arrive at the host with no idea whose home they belong to. den
      resolves a quirk value that takes scope arguments at the scope that
      produced it, so the username is captured before the data leaves.

      Seeded is not the same as persisted, and neither implies the other:
      .ssh/known_hosts is persisted but never seeded. An aspect that seeds a
      file almost always wants it in home-persist too, and core.seed asserts
      that rather than trusting me to remember.
    '';
  };

  den.policies.seed =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "seed" [ pipe.expose ]) ];

  den.quirks.syncthing-peer = {
    description = ''
      One device in the Syncthing mesh: { name = "endgame"; id = "O5ZE76L-..."; }
      and optionally addresses = [ "tcp://..." ] for a peer that can't be found
      by local discovery.

      Produced once per host and consumed once per user, so it crosses both the
      fleet (host to host) and the scope boundary (host to user). den.mesh has
      the producer, the schema entry that makes every host emit one, and the
      collectAll policy that gathers them; apps/sync/syncthing.nix just reads
      the pool it is handed.

      That indirection is the point. The aspect used to fold den.hosts by hand
      and merge in my NAS, which made it the one app aspect that couldn't be
      lifted into another config. It now knows how to configure Syncthing and
      nothing about which machines I own.
    '';
  };

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
  # works first time. 'firewall' really does need it, since apps.sync.syncthing
  # comes in from the user aspect and opens 22000 and 21027.
  den.schema.user.includes = [
    den.policies.persist
    den.policies.firewall
    den.policies.seed
  ];
}
