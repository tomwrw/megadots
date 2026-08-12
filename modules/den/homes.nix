{ den, megadots, ... }:
{
  # The same user aspect, evaluated with no NixOS underneath it.
  #
  # This exists to keep modules/megadots/ honest. Every aspect in there is
  # supposed to describe an application rather than my fleet, and the way that
  # claim rots is an aspect quietly growing a dependency on something only a
  # NixOS host provides - impermanence's home.persistence option, a sops secret
  # placed by the system, a firewall port, a host name. None of those fail
  # loudly at user scope; they just make the aspect unusable anywhere else,
  # which I'd find out on the day I actually needed it. Building this target in
  # CI turns that into a broken build now.
  #
  # It has already earned its keep: apps/shell/zsh.nix took a host argument so
  # two aliases could run nixos-rebuild, which made den treat the whole aspect
  # as scope-parametric and drop it here - silently, leaving a shell with no
  # fzf, no completion and dotDir back at $HOME. Those aliases now come from
  # core.nix at host scope.
  #
  # A bare key, not "tomwrw@somehost". The user@host form binds the home to a
  # host already in den.hosts, which would test nothing new - both real
  # machines cover that path. Unbound is the case worth proving: host is null,
  # and this is what the config looks like on someone else's Ubuntu.
  den.homes.x86_64-linux.tomwrw = {
    excludes = [
      # Names its secrets syncthing/${host.name}/... and opens firewall ports.
      # Neither exists without a host, and pretending otherwise would mean
      # inventing a device identity for a machine that has none.
      #
      # Belt and braces, not load-bearing: I checked, and with this line
      # deleted the aspect still contributes nothing here, because its class
      # module asks for a host and den drops a module whose scope arguments it
      # can't satisfy. Which is precisely why the line stays. Relying on that
      # is relying on a silent drop, and the day someone makes this aspect
      # host-independent - I nearly did, moving 'host' into the class module -
      # it would quietly switch itself on here with no secrets behind it.
      # Saying "not this one" out loud costs a line and survives that change.
      megadots.apps.sync.syncthing
    ];
  };

  # On the schema rather than on the home above, because den.homes entities
  # take their aspect from den.aspects.<name> - which for this home is
  # den.aspects.tomwrw, the very same user aspect both hosts use. An 'includes'
  # written on the entity is not read at all (silently - it is freeform), and
  # adding fonts to the user aspect would put them on the NixOS hosts too,
  # where fonts.packages already installs them system-wide.
  #
  # Reads as a rule rather than an exception anyway: a home with no system
  # underneath it has no system font path, so every standalone home needs this.
  #
  # 'provides.home' auto-delivers nowhere, which is the whole reason it can be
  # named that. den registers a cross-policy for every provides.<name> that is
  # not a schema entity kind and filters out the ones that are, so this only
  # ever arrives where it is asked for. Renaming it 'standalone' would quietly
  # create a delivery policy aimed at an entity nobody has.
  den.schema.home.includes = [ megadots.desktop.fonts.provides.home ];
}
