_: {
  # Graphics drivers, including the 32-bit stack games need.
  den.aspects.graphics = {
    nixos = _: {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # Mesa's compiled-shader caches. / is rolled back every boot and ~/.cache
    # goes with it, so without this every game recompiles every shader on the
    # first launch after a reboot - the stutter people blame on the driver.
    # radv_builtin_shaders is the driver's own set, mesa_shader_cache is
    # everything an app has compiled through it. Host scope, so the home path
    # takes the provides.to-users route like apps/steam.nix.
    provides.to-users.persist.home.directories = [
      ".cache/mesa_shader_cache"
      ".cache/radv_builtin_shaders"
    ];
  };
}
