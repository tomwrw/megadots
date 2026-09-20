_: {
  # Kernel sysctls and boot parameters that narrow the default attack surface.
  den.aspects.hardening.nixos = _: {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      # 1, not 2. Level 2 applies constant blinding to *every* BPF program,
      # privileged ones included - and core/scheduler.nix puts a sched_ext
      # scheduler's hot path in BPF. Blinding exists to stop an unprivileged
      # program spraying the JIT, and unprivileged BPF is off above, so 1 is
      # the same protection at zero cost.
      "net.core.bpf_jit_harden" = 1;
      "kernel.kexec_load_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
    };

    # Normal priority, not mkDefault. A mkDefault list definition of
    # boot.kernelParams gets thrown away entirely, because nixpkgs already
    # defines it at normal priority, so lowering these would delete them. Same
    # trap from the other side in hardware/surface-pro.nix.
    #
    # No lockdown=confidentiality. The CachyOS kernel does build
    # CONFIG_SECURITY_LOCKDOWN_LSM, but nixpkgs' security.lsm default is
    # landlock,yama,bpf, so the LSM is never initialised and the parameter is
    # inert. Turning it on means adding "lockdown" to security.lsm, and then
    # confidentiality mode blocks BPF reads of kernel memory - which would
    # have to be checked against the sched_ext scheduler first.
    #
    # No init_on_free. init_on_alloc already zeroes memory before anything
    # sees it, which is the uninitialised-memory-disclosure case; init_on_free
    # zeroes it a second time on the way out to blunt use-after-free reads,
    # and the patch author's own numbers put that at ~5% on average, more on
    # allocation-heavy work. The only line in here that trades resilience for
    # speed, and a conscious one. slab_nomerge and page_alloc.shuffle stay:
    # both are near-free, and the kernel is built to make use of them.
    boot.kernelParams = [
      "init_on_alloc=1"
      "slab_nomerge"
      "page_alloc.shuffle=1"
      "vsyscall=none"
    ];
  };
}
