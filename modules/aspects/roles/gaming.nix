{ den, ... }:
{
  den.aspects.roles.gaming = {
    # Host-scope: system services and programs.
    includes = [
      den.aspects.apps.gaming.steam
      den.aspects.apps.gaming.sunshine
    ];

    # User-scope: delivered to every user on a host that takes this role.
    #
    # These used to hang off 'provides.endgame' in the tomwrw aspect, keyed by
    # host NAME - so a second gaming host would have meant editing the user
    # file, and renaming the host would have silently disabled them (den matches
    # provides.<name> against the host name and does not error on no match).
    # Expressed here once, the role is the only thing that decides.
    provides.to-users.includes = [
      den.aspects.apps.gaming.mangohud
      den.aspects.apps.gaming.emulation
      den.aspects.apps.gaming.minecraft
    ];
  };
}
