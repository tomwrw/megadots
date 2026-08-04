_: {
  den.aspects.core.security.hardening.nixos = _: {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.kexec_load_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
    };

    # Normal priority deliberately: a mkDefault list definition of
    # boot.kernelParams is discarded wholesale (nixpkgs' kernel.nix already
    # defines the option at normal priority), so lowering these would delete
    # them. See hardware/surface-pro.nix for the same trap from the other side.
    #
    # No "lockdown=confidentiality" here: the CachyOS kernel is built without
    # CONFIG_SECURITY_LOCKDOWN_LSM, so the parameter was silently inert -
    # /sys/kernel/security/lsm never listed it and /sys/kernel/security/lockdown
    # did not exist. Re-adding it needs both a kernel that builds the LSM and
    # `security.lsm = [ "lockdown" ];`, since NixOS emits an explicit lsm= list.
    boot.kernelParams = [
      "init_on_alloc=1"
      "init_on_free=1"
      "slab_nomerge"
      "page_alloc.shuffle=1"
      "vsyscall=none"
    ];
  };
}
