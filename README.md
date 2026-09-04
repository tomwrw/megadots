<p align="center">
  <img src="./assets/megadots.png" width="400" />
</p>

# Introduction

[![check](https://github.com/tomwrw/megadots/actions/workflows/check.yml/badge.svg)](https://github.com/tomwrw/megadots/actions/workflows/check.yml)

My NixOS configuration, built on the den framework + Home Manager + Flakes. This framework provides libraries that make implementing the dendritic pattern a breeze. I publish this repo to help others, as I found other people's repos extremely helpful when learning Nix/NixOS. Hopefully I can return the favour.

> **Note:** This is my personal config. Any branch other than `main` should be considered a work in progress. Hardware configs, hostnames, secrets and user attributes are unique to me - you'll need to bring your own.

## About

This is the fourth iteration of my NixOS configuration. I've been daily driving NixOS for nearly 2 years. Most recently, I have dabbled with the dendritic pattern and with the den framework, I have found a suitable home for my configs.

You can find my other configs archived in named branches for review if you want to check out other management styles, like megadots-classic and megadots-dendritic.

I'm not a developer. I'm a tinkerer with a consultancy job in a technical field who got curious about declarative system management and fell down the NixOS rabbit hole. This project has genuinely brought some fun back into computing for me.

## Features.

- :desktop_computer: **NixOS** aspects for multiple hosts.
- :house: **Home Manager** as a NixOS module.
- :ghost: **sops-nix** for secrets management, with dedicated age key support for hosts and users.
- :key: **FIDO2 hardware keys** (Token2 PIN+) for SSH, with an optional extra LUKS unlock keyslot alongside the passphrase.
- :camera_flash: **Impermanence** on an ephemeral btrfs root — `/` is restored from a blank
  snapshot on every boot, and state is opt-in per aspect.
- :cop: **Secure Boot** via lanzaboote with automatic key generation and enrollment.
- :snowflake: **Flake** with the den framework for modular, composable host and user aspects.
- :floppy_disk: **Disko** for declarative disk partitioning.
- :anger: **CachyOS kernel** for a gaming optimised kernel (opt-in per host).
- :art: **Stylix** for consistent base16 theming at both scopes - the login screen, TTY
  and plymouth as well as the user session - driven by a single `theme` quirk.
- :rocket: **nixos-anywhere** for bare metal remote deployment.

## The hosts.

| Host | Machine | Desktop | Bootloader | Kernel | Aspects |
|---|---|---|---|---|---|
| `endgame` | AMD desktop (zen4) | GNOME | lanzaboote (Secure Boot) | CachyOS `lto-znver4` | base, workstation, gaming, dev |
| `flatmate` | Microsoft Surface Pro (Intel) | GNOME | systemd-boot | nixpkgs default | base, workstation, dev |

Both run an ephemeral btrfs root on LUKS, the same user and the same desktop. `/` is its
own subvolume, deleted and restored from a read-only `root-blank` snapshot by an initrd
service on every boot; `/nix`, `/persist` and swap are separate subvolumes that survive.
`/home` deliberately sits *inside* the rolled-back root, so user state is opt-in through
`persist.home` in the aspect that owns it, exactly as system state is opt-in through
`persist.system`. Touch `dont-wipe` at the top of the btrfs volume to skip the wipe for a
boot.

The desktop is a host's choice, not the `workstation` aspect's - the same way the
bootloader is. That is what let `endgame` run COSMIC for a while and go back to GNOME
without anything shared changing.

## What den gives you.

If you have not met [den](https://github.com/denful/den) before, four terms explain
almost everything in this repo:

- **aspect** - a named, self-contained feature. It can carry a `nixos` block, a
  `homeManager` block, or both. Aspects are never split by class, only by concern:
  [bluetooth](modules/aspects/hardware/bluetooth.nix) owns its NixOS options *and* the
  state it needs persisted, in one file.
- **`includes`** - how a host, a user or another aspect opts in.
  [roles/base.nix](modules/aspects/roles/base.nix) is nothing but a list of aspects every
  host takes.
- **`provides.to-users`** - a host-scope aspect handing configuration to every user on
  that host. Needed because a bare `homeManager` block on a host-scope aspect is silently
  dropped; [gnome](modules/aspects/desktop/gnome.nix) uses it to deliver dconf settings.
- **quirk** + **policy** - a quirk is a named data channel an aspect writes to; a policy
  routes it. All of both live in [den/quirks.nix](modules/den/quirks.nix).

### Start here.

The shortest path through the repo, in reading order:

1. [den/defaults.nix](modules/den/defaults.nix) - what every host and user gets, unasked.
2. [den/hosts.nix](modules/den/hosts.nix) - the roster: per-host facts, and nothing else.
3. [hosts/endgame/default.nix](modules/hosts/endgame/default.nix) - a host as a readable
   manifest of the aspects it takes.
4. [aspects/roles/base.nix](modules/aspects/roles/base.nix) - a role is just an aspect
   that is all `includes`.
5. [aspects/core/networking.nix](modules/aspects/core/networking.nix) - a real aspect, and
   the single consumer of the firewall quirk.
6. [den/quirks.nix](modules/den/quirks.nix) - every channel that crosses a scope.

## Layout.

Everything lives under `modules/`, discovered automatically by
[import-tree](https://github.com/vic/import-tree) - there are no manual import lists;
dropping a file in is enough. `flake.nix` is generated by
[flake-file](https://github.com/vic/flake-file) (`nix run .#write-flake`), so each module
declares the flake inputs it needs right next to the code that uses them via
`flake-file.inputs`.

```
modules/
├── aspects/              # every aspect, filed by what it is
│   ├── roles/            #   base, workstation, gaming, dev
│   ├── core/             #   the baseline: boot, disks, nix, networking, secrets
│   ├── desktop/          #   cosmic, gnome, stylix, fonts, networkmanager
│   ├── hardware/         #   opt-in support, and per-model profiles
│   ├── virtualisation/   #   libvirt
│   └── apps/             #   every user-facing app, one file each
├── den/                  # defaults, the host roster, the schema, the quirks
├── flake/                # flake plumbing: inputs, treefmt, checks, devShell, deploy
├── hosts/                # one directory per host: its aspects, and its _hardware.nix
│   ├── endgame/
│   └── flatmate/
└── users/tomwrw/         # the user, itself just another aspect
```

Aspect names are short and flat: `modules/aspects/core/sops.nix` declares
`den.aspects.sops`, and `modules/aspects/apps/signal.nix` declares `den.aspects.signal`.
The directories are filing, not namespace - an `includes` list reads as a list of names
rather than a list of paths. Host-specific hardware is *not* an aspect: each host imports
its own `_hardware.nix` directly, and the `_` prefix is what stops
[import-tree](https://github.com/vic/import-tree) picking it up as a module of its own.

Roles are aspects too. `base`, `workstation`, `gaming` and `dev` are ordinary aspects that
happen to be mostly `includes`, so there is one concept to learn rather than two.

### Quirks: how anything crosses a scope.

An aspect says what it needs; something else decides how to apply it. All four channels,
and every policy that routes one, live in [den/quirks.nix](modules/den/quirks.nix).

```nix
# aspects/apps/sunshine.nix says only this...
firewall.tcp = [ 47984 47989 47990 48010 ];

# ...and aspects/core/networking.nix is the single place that turns every such
# declaration into interface-scoped rules on host.network.lanInterface.
```

| Quirk | Carries |
|---|---|
| `persist` | `system` paths for `environment.persistence`, `home` paths for `home.persistence` |
| `firewall` | LAN-scoped ports, aggregated onto the host's interface |
| `theme` | the base16 scheme and wallpaper, read by Stylix at *both* scopes |
| `syncthing-peer` | one device in the mesh, produced per host and consumed per user |

Note the trap: a quirk emitted from a **user-scope** aspect only reaches the host if an
expose policy is registered for it in `den.schema.user.includes` - without one it is
discarded silently, with no error. `syncthing` is included at user scope, so its firewall
ports depend on exactly that. Expose *copies* rather than moves, which is why one
`persist` quirk can carry both halves: the `home` entries stay readable in the user scope
they are consumed in.

The Syncthing mesh is the same machinery at fleet scale, and is built without the aspect
knowing the fleet exists: a producer on `den.schema.host.includes` makes every host
announce its own id, a `pipe.collectAll` policy gathers all of them into the *user* scope,
and [apps/syncthing.nix](modules/aspects/apps/syncthing.nix) reads the pool it is handed.
Peers that aren't den hosts - the NAS - are appended to the same pipe from
`fleet.externalPeers` in [den/hosts.nix](modules/den/hosts.nix), so they arrive
indistinguishable from a fleet host.

### Checks.

`nix flake check` builds both hosts, runs `treefmt`, and greps the tree for plaintext key
material. That is all of it - there are no fleet invariants. A broken one shows up when
the machine boots, deploys are atomic, and `nixos-rebuild` builds before it switches.

The secrets scan is the exception worth keeping: committing a private key to a public repo
is the one mistake that cannot be taken back. It is in
[flake/checks.nix](modules/flake/checks.nix), and it assembles its own search strings from
fragments so that the file does not match itself.

### Deliberate Nix settings.

[core/nix.nix](modules/aspects/core/nix.nix) sets two options worth calling out, both
security trade-offs:

- `nix.settings.trusted-users = [ "root" "@wheel" ]` - lets any `wheel` member
  build/substitute arbitrary derivations and push closures via `nixos-rebuild
  --target-host`. A single-admin-LAN trade-off: fine as the sole admin of this fleet, not
  something to carry into a multi-user or shared-admin setup without thought.
- `nix.settings.allow-import-from-derivation = true` - required because Stylix's base16
  scheme reader does an IFD (`readFile`s a YAML out of the `base16-schemes` derivation at
  eval time). Without it, evaluation fails outright.

### Known trade-offs.

Things that are deliberate rather than missed, so you can judge whether they suit you:

- **The COSMIC aspect is carried, not used.** No host has run COSMIC since `endgame` moved
  back to GNOME, and nothing evaluates it any more - so treat
  [desktop/cosmic.nix](modules/aspects/desktop/cosmic.nix) as last-known-good rather than
  known-to-work. It stays because switching back is a one-line change.
- **COSMIC is configured by hand, not declaratively.** home-manager has no COSMIC modules
  at all, so there is no `programs.cosmic-*` and no dconf equivalent. Every panel, theme
  and shortcut choice is made in the UI and written to `~/.config/cosmic` as RON, which
  makes the `persist.home` entry in that aspect the *entire* mechanism by which the
  desktop survives a boot - the opposite of [gnome.nix](modules/aspects/desktop/gnome.nix),
  where `dconf.settings` carries the decisions that matter.
- **Stylix does not theme COSMIC.** There is no cosmic target in the Stylix version this
  flake pins. GTK applications still follow the palette, but COSMIC's own shell uses its
  own theme system and is set by hand. It costs nothing today, with both hosts on GNOME.
- **Stylix's own Home Manager auto-import is switched off.** Stylix is applied at both
  scopes, each half reading the same `theme` quirk. Leaving
  `homeManagerIntegration.autoImport` at its default has Stylix push its Home Manager
  module into `home-manager.sharedModules` as well; the module system keys that
  differently from den's import, evaluates it twice, and dies on `stylix.base16` being
  read-only and set twice.
- **LAN-scoped firewall rules are weaker on a laptop.** Every port is opened on
  `host.network.lanInterface` rather than globally, which is a real improvement on a
  desktop. On `flatmate` that interface is the Wi-Fi adapter, so it is the same interface
  at home and in a cafe - SSH and Syncthing are reachable on any network it joins. Source
  subnet matching (which needs the nftables backend) is the actual fix.
- **`trusted-users` includes `@wheel`, on a host that signs its own boot chain.** A trusted
  user can get arbitrary content into the store, and `endgame` is the machine that then
  signs whatever it boots with its Secure Boot key.
- **A third-party binary cache supplies that host's kernel.**
  [core/nyx-cache.nix](modules/aspects/core/nyx-cache.nix) trusts
  [chaotic-cx/nyx](https://www.nyx.chaotic.cx/) for prebuilt CachyOS kernels, and for
  proton-cachyos in [apps/steam.nix](modules/aspects/apps/steam.nix). It composes with the
  point above: a compromised cache could hand `endgame` a kernel its own Secure Boot chain
  would then sign and boot without complaint. Accepted so that a znver4 LTO kernel does not
  have to be compiled locally on every bump. Only hosts that take a package from nyx trust
  it - the aspect is included by the two that do, and `flatmate` has neither.
- **Real hardware serials are in the roster.** `disk.id` in
  [den/hosts.nix](modules/den/hosts.nix) carries the NVMe serial of each machine.
  `/dev/disk/by-id/` is the correct stable identifier - disko partitions on it - so it
  cannot come from sops, which is decrypted far too late to place a partition. A serial is
  an identifier, not a credential; the realistic cost is that it fingerprints the hardware.

## Usage.

This configuration has multiple system entry points. At the moment, I am a single user (tomwrw) managing multiple machines.

### Prerequisites.

- Nix with flakes enabled (`experimental-features = nix-command flakes`).
- `just`, `sops` and `age`. `nix develop` provides these plus `nixfmt`, `nvd`,
  `ssh-to-age` and `nixos-anywhere` - see [devshell.nix](modules/flake/devshell.nix).
- An age keypair per host and per user, and a FIDO2 token if you want the extra LUKS
  keyslot. The deploy recipe expects these on a removable drive at the path in the
  `usb` variable at the top of the [justfile](justfile).

### Getting Started.

Everything goes through `just`. Run it bare to list the recipes.

```bash
just                      # list recipes
just build endgame        # build a host's closure locally (no activation)
just diff endgame         # build, then nvd diff against the running system
just rebuild endgame      # switch a remote host (pushes a locally-built closure)
just deploy endgame       # bare-metal install via nixos-anywhere (formats disks)
just check                # build both hosts, format check, secrets scan
just fmt                  # nixfmt + deadnix + statix via treefmt
just update               # nix flake update
just gc                   # collect garbage older than 30 days
just enroll-fido2 endgame # add the inserted token to the LUKS header
just secrets-edit secrets/users/tomwrw.yaml
just secrets-updatekeys   # re-sync sops recipients after editing .sops.yaml
```

`just check` builds both hosts, checks formatting and greps for plaintext key material.
Building a host is the check that matters: it catches anything that has stopped
evaluating or building.

CI does not build the closures. It runs the same three checks, then instantiates every
host - forcing `toplevel.drvPath` evaluates the whole module system, and every `assertions`
entry in the tree with it, without realising a single output. The host list is derived from
`nixosConfigurations`, so a new host is covered without touching
[check.yml](.github/workflows/check.yml).

### Bootstrapping a host from scratch.

Four things have to be in place before `just deploy <name>` will produce a working
machine.

1. **USB key material.** The USB mirrors the destination: whatever is under
   `<usb>/users/<username>/` is copied to that user's home, at the same relative path.
   There is no manifest anywhere in this repo, so adding a key is a copy on the USB and
   no config change at all.

   ```
   <usb>/hosts/<hostname>/age.txt                        # -> /persist/var/lib/sops-nix/key.txt
   <usb>/users/<username>/.config/sops/age/keys.txt      # -> ~/.config/sops/age/keys.txt
   <usb>/users/<username>/.ssh/id_ed25519{,.pub}
   <usb>/users/<username>/.ssh/id_ed25519_sk_primary{,.pub}   # FIDO2 handles; useless
   <usb>/users/<username>/.ssh/id_ed25519_sk_backup{,.pub}    # without the physical token
   ```

   Modes are copied from the USB with `cp -a`, so a private key has to be `0600` *there*.
   Ownership is handled by nixos-anywhere's `--chown`, which runs during the install -
   `--extra-files` copies as root.

   The `usb` path itself is a variable at the top of the [justfile](justfile).

2. **A `creation_rules` block for the new host** in [.sops.yaml](.sops.yaml) - one per
   secrets file, listing its recipients. Adding a key to the recipient list is not enough;
   without its own rule the host's secrets are encrypted to nobody. Then run
   `just secrets-updatekeys`.
3. **`secrets/hosts/<name>.yaml`** with at least `users/<user>/password`. Evaluation
   interpolates this filename from the hostname, so a missing file fails the build.
4. **`syncthing/<name>/{key,cert,guiPassword}` in `secrets/users/<user>.yaml`** - the
   syncthing secrets are keyed by *host* but live in the *user* file
   ([apps/syncthing.nix](modules/aspects/apps/syncthing.nix)). Miss these and the host
   builds fine, then Home Manager activation fails on the new machine.
5. **The roster entry** in [modules/den/hosts.nix](modules/den/hosts.nix): disk id (a
   stable `/dev/disk/by-id/` path), swap size, LAN interface name from `ip -br link`, and
   the Syncthing device id.
6. **`modules/hosts/<name>/`** with a `default.nix` listing the aspects it takes and a
   `_hardware.nix` from `nixos-generate-config`.

Then boot the target from a NixOS installer ISO, set a password for the `nixos` user so
SSH works, and run `just deploy <name>`. nixos-anywhere partitions with disko, copies the
USB tree into /persist, chowns it to the user, and installs. The machine comes up with its
secrets decryptable and its keys in place - no second pass, nothing to do by hand.

### Adapting this for yourself.

Fork it, then: replace `modules/users/` and `modules/hosts/` with your own, empty the
roster in `modules/den/hosts.nix`, regenerate `.sops.yaml` with your own age keys, and
replace `assets/` (the wallpapers are not covered by this repo's licence - see
[LICENSE](LICENSE)). The parts worth keeping are `modules/aspects/` and
`modules/den/quirks.nix` - no aspect there names a host or a user, so they port across
unchanged.

## Community.

I learn by doing. None of this would be possible without the copious amounts of developers and repos that share their content freely for others like me to dissect and study. There are many, but to name a few - shout outs go to:

[ryan4yin](https://github.com/ryan4yin/) for their [awesome book](https://nixos-and-flakes.thiscute.world/) on NixOS (if you haven't started here, then give it a whirl - it really was great) and the [i3 Kickstarter repo](https://github.com/ryan4yin/nix-config/blob/i3-kickstarter/). Both excellent resources to help me understand the power of NixOS.

The majority of my config structure was heavily influenced by the awesome [Misterio77](https://github.com/Misterio77/). Not only did his [Nix Starter Configs](https://github.com/Misterio77/nix-starter-configs) help guide me early on, but his own [Nix Config](https://github.com/Misterio77/nix-config/tree/main) repo was a great inspiration on how to construct and model a modular Nix configuration.

#### And more inspiration...

- Nvim - https://github.com/Nvim (https://github.com/Nvim/snowfall)
- mtrsk - https://github.com/mtrsk (https://github.com/mtrsk/nixos-config)
- runarsf - https://github.com/runarsf (https://github.com/runarsf/dotfiles)
- librephoenix - https://github.com/librephoenix (https://github.com/librephoenix/nixos-config)
- frost-phoenix - https://github.com/Frost-Phoenix (https://github.com/Frost-Phoenix/nixos-config)
