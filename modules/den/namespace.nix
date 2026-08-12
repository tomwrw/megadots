{ inputs, ... }:
{
  # Publishes everything under modules/megadots/ as flake.denful.megadots, so
  # another den config can add this repo as an input and include an aspect
  # straight out of it.
  #
  # The boundary is the point, and it is drawn in code rather than in this
  # README's prose:
  #
  #   megadots.*     - the library. Aspects that describe an application or a
  #                    subsystem and name no host, no user and no machine of
  #                    mine. Everything under modules/megadots/.
  #   den.aspects.*  - the config. My hosts, my user, my roles, my fleet
  #                    plumbing. Composition is personal taste and is nobody
  #                    else's starting point.
  #
  # Anything that has to move from the left column to the right is telling me
  # it was never reusable, which is the check I want on every future aspect.
  #
  # 'true' as the second argument is what makes it an output rather than a
  # purely internal namespace. It also brings a 'megadots' module argument
  # aliased to den.ful.megadots, which is how the roles refer to library
  # aspects.
  imports = [ (inputs.den.namespace "megadots" true) ];

  # den materialises a container node as an aspect in its own right, so
  # 'megadots.apps' is includable and arrives with a default description of
  # "Aspect apps". These are the five that anyone reading flake.denful.megadots
  # meets first, so they say something. checks.nix asserts they stay set, which
  # is also what catches a stray setting landing in the namespace: the alias
  # makes 'megadots.anything = ...' legal, and it is then exported as though it
  # were an aspect. That is not hypothetical - megadots.externalPeers did
  # exactly this until it moved to fleet.externalPeers.
  megadots = {
    apps.description = "Applications, all user scope. Nothing here needs a NixOS host.";
    core.description = "The baseline every machine gets: boot, disks, firmware, network, secrets, persistence.";
    desktop.description = "The graphical session and everything themed by it.";
    hardware.description = "Opt-in hardware support, and per-model profiles.";
    virtualisation.description = "Running other operating systems.";
  };
}
