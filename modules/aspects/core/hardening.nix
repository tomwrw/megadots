_: {
  # Kernel sysctls and boot parameters that narrow the default attack surface.
  den.aspects.hardening.nixos = _: {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.kexec_load_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
    };

    # Normal priority, not mkDefault. A mkDefault list definition of
    # boot.kernelParams gets thrown away entirely, because nixpkgs already
    # defines it at normal priority, so lowering these would delete them. Same
    # trap from the other side in hardware/surface-pro.nix.
    #
    # No lockdown=confidentiality. The CachyOS kernel is built without
    # CONFIG_SECURITY_LOCKDOWN_LSM, so it did nothing at all. Putting it back
    # needs a kernel with the LSM plus 'security.lsm = [ "lockdown" ];'.
    boot.kernelParams = [
      "init_on_alloc=1"
      "init_on_free=1"
      "slab_nomerge"
      "page_alloc.shuffle=1"
      "vsyscall=none"
    ];
  };
}
