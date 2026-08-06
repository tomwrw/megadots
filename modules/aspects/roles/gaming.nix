{ den, ... }:
{
  den.aspects.roles.gaming = {
    # Host scope, system services and programs.
    includes = [
      den.aspects.apps.gaming.steam
      den.aspects.apps.gaming.sunshine
    ];

    # User scope, given to every user on a host taking this role.
    #
    # These used to hang off 'provides.endgame' in the tomwrw aspect, keyed by
    # host name. A second gaming host would have meant editing the user file,
    # and renaming a host would have quietly switched them off, since den
    # matches provides.<name> against the host name and doesn't complain when
    # nothing matches. Said once here, the role decides.
    provides.to-users.includes = [
      den.aspects.apps.gaming.mangohud
      den.aspects.apps.gaming.emulation
      den.aspects.apps.gaming.minecraft
    ];
  };
}
