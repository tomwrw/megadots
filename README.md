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
- :art: **Stylix** for consistent base16 theming across the user environment.
- :rocket: **nixos-anywhere** for bare metal remote deployment.

## The hosts.

| Host | Machine | Bootloader | Kernel | Roles |
|---|---|---|---|---|
| `endgame` | AMD desktop (zen4) | lanzaboote (Secure Boot) | CachyOS `latest-zen4` | base, workstation, gaming, dev |
| `flatmate` | Microsoft Surface Pro (Intel) | systemd-boot | nixpkgs default | base, workstation |

Both run an ephemeral btrfs root on LUKS, GNOME, and the same user. `/` is its own
subvolume, deleted and restored from a read-only `root-blank` snapshot by an initrd
service on every boot; `/nix`, `/persist` and swap are separate subvolumes that survive.
`/home` deliberately sits *inside* the rolled-back root, so user state is opt-in through
`home.persistence` in the aspect that owns it, exactly as system state is opt-in through
`core.impermanence`. Touch `dont-wipe` at the top of the btrfs volume to skip the wipe for
a boot.

## What den gives you.

If you have not met [den](https://github.com/denful/den) before, five terms explain
almost everything in this repo:

- **aspect** - a named, self-contained feature. It can carry a `nixos` block, a
  `homeManager` block, or both. Aspects are never split by class, only by concern:
  [bluetooth](modules/megadots/hardware/bluetooth.nix) owns its NixOS options *and* the
  state it needs persisted, in one file.
- **`includes`** - how a host or user opts in. [roles/base.nix](modules/roles/base.nix)
  is nothing but a list of aspects every host takes.
- **`provides.to-users`** - a host-scope aspect handing configuration to every user on
  that host. Needed because a bare `homeManager` block on a host-scope aspect is silently
  dropped; [gnome](modules/megadots/desktop/gnome.nix) uses it to deliver dconf settings.
- **`den.batteries.*`** - den's own prebuilt aspects (defining a user, setting a login
  shell). Used in [den/defaults.nix](modules/den/defaults.nix) and the user aspect.
- **quirk** + **policy** - a quirk is a named data channel an aspect writes to; a policy
  routes it. See [den/quirks.nix](modules/den/quirks.nix) and the section below.

### Start here.

The shortest path through the repo, in reading order:

1. [den/defaults.nix](modules/den/defaults.nix) - what every host and user gets, unasked.
2. [den/hosts.nix](modules/den/hosts.nix) - the roster: per-host facts, and nothing else.
3. [hosts/endgame/default.nix](modules/hosts/endgame/default.nix) - a host as a readable
   manifest of the roles it takes.
4. [roles/base.nix](modules/roles/base.nix) - a role is just a list of aspects.
5. [aspects/core/networking.nix](modules/megadots/core/networking.nix) - a real aspect, and
   the single consumer of the firewall quirk.
6. [flake/checks.nix](modules/flake/checks.nix) - the fleet invariants that keep all of the
   above honest.

## Layout.

Everything lives under `modules/`, discovered automatically by [import-tree](https://github.com/vic/import-tree) - there are no manual import lists; dropping a file in is enough. `flake.nix` is generated by [flake-file](https://github.com/vic/flake-file) (`nix run .#write-flake`), so each module declares the flake inputs it needs right next to the code that uses them via `flake-file.inputs`.

```
modules/
├── megadots/             # the exported library — everything here is denful.megadots:
│   ├── core/             #   always-on baseline (nix, networking, boot, firmware,
│   │                     #     impermanence, sops, openssh, hardening, fido2, …)
│   ├── hardware/         #   opt-in hardware support: graphics, audio, bluetooth,
│   │                     #     and per-model profiles
│   ├── desktop/          #   gnome, stylix, fonts, networkmanager
│   ├── virtualisation/   #   libvirt (room for docker/podman siblings later)
│   └── apps/             #   every user-facing app, one directory per category
│       ├── dev/          #     apps.dev.*
│       ├── gaming/       #     apps.gaming.*
│       ├── messaging/    #     apps.messaging.*
│       └── …             #     browsers, media, monitoring, productivity,
│                         #     security, shell, storage, sync, terminals
├── den/                  # den setup: defaults, schema, the roster, quirks, the
│                         #   syncthing mesh, the standalone home, the namespace
├── flake/                # flake plumbing: treefmt, checks, devShell, secrets scan
├── hosts/                # one directory per host: its roles, and its _hardware.nix
│   ├── endgame/
│   └── flatmate/
├── roles/                # composite bundles hosts include (base, workstation, gaming, dev)
└── users/tomwrw/         # the Home Manager user, itself just another aspect
```

The path *is* the name, literally: `modules/megadots/core/sops.nix` declares
`megadots.core.sops`, and `modules/megadots/apps/messaging/signal.nix` declares
`megadots.apps.messaging.signal`. The folder is called `megadots/` for exactly that
reason - it is the namespace, not a category, so there is no translation step between
what you read in an `includes` list and where you go to find it. Host-specific hardware
is *not* an aspect: each host imports its own `_hardware.nix` directly, and the `_`
prefix is what stops [import-tree](https://github.com/vic/import-tree) picking it up as
a module of its own.

No aspect nests below its own concern for the sake of grouping. There is no
`core/security/` folder: `core.sops`, `core.openssh`, `core.hardening` and `core.fido2`
sit directly in `core/`, because the extra word disambiguated nothing and cost a
directory level. The same rule killed the last node that carried config *and* had
children - firmware was `megadots.hardware`, a name that read as "the hardware tree"
while meaning "fwupd and redistributable firmware". It is `megadots.core.firmware` now,
and `hardware/` is a pure container of things you opt into.

`megadots.*`, not `den.aspects.*`, and the split is the whole point of the layout.
[namespace.nix](modules/den/namespace.nix) publishes everything under `modules/megadots/` as
`flake.denful.megadots`, so another den config can add this repo as an input and include
an aspect straight out of it:

```nix
# in someone else's flake
{
  imports = [ (inputs.den.namespace "megadots" [ inputs.megadots ]) ];
  den.aspects.their-host.includes = [ megadots.core.impermanence megadots.apps.shell.zsh ];
}
```

Which half a thing belongs to is a real question, answered the same way every time:

| | |
|---|---|
| `megadots.*` | the **library** - aspects that describe an application or a subsystem and name no host, no user and no machine of mine. `modules/megadots/`. |
| `den.aspects.*` | the **config** - my hosts, my user, my roles, the fleet plumbing in `modules/den/`. Composition is personal taste and is nobody else's starting point. |

An aspect that has to move from the left column to the right is telling you it was never
reusable. That is the check this boundary buys, and it is enforced rather than aspirational:
the `namespace` check in [checks.nix](modules/flake/checks.nix) asserts the export contains
exactly the five trees and nothing else, because `den.namespace` aliases the whole
`megadots` option path - so any plain setting written under it is legal, silently published
as though it were an aspect, and shows up in someone else's config as a broken include.
`megadots.externalPeers` did exactly that before it became `fleet.externalPeers`.

The unit of composition is the **aspect**: a named, self-contained feature that can carry a NixOS side, a Home Manager side, or both - never split by class, only by concern. Hosts and users opt in via `includes`. For example, [fonts](modules/megadots/desktop/fonts.nix) installs its font set at the system level for every host, and offers the same set as a named `home` sub-aspect for a standalone Home Manager setup with no system font path to fall back on (pulled in by `den.schema.home` in [den/homes.nix](modules/den/homes.nix), and an illustration of naming a sub-aspect rather than leaving a silently inert `homeManager` block on a host-scope aspect):

```nix
{
  megadots.desktop.fonts = {
    nixos = { pkgs, ... }: { fonts.packages = fontPkgs pkgs; };
    provides.home.homeManager = { pkgs, ... }: { home.packages = fontPkgs pkgs; };
  };
}
```

Cross-cutting data flows through den pipes rather than hard-coding. The Syncthing device
mesh is the clearest example, and it is built without the aspect knowing the fleet exists:
[den/mesh.nix](modules/den/mesh.nix) puts a producer on `den.schema.host.includes` so every
host announces its own `syncthing.id`, then a `pipe.collectAll` policy gathers all of them
into the *user* scope where [apps/sync/syncthing.nix](modules/megadots/apps/sync/syncthing.nix)
reads the pool it is handed. Peers that aren't den hosts - my NAS - are appended to the same
pipe from `megadots.externalPeers`, so they arrive indistinguishable from a fleet host.

That aspect used to fold `den.hosts` by hand and merge my NAS in, which made it the one app
aspect nobody else could lift into their own config. It now knows how to configure Syncthing
and nothing about which machines I own.

Cross-cutting *configuration* flows through den quirks, declared in
[den/quirks.nix](modules/den/quirks.nix). An aspect says what it needs and something
else decides how to apply it:

```nix
# apps/sunshine.nix says only this...
firewall.tcp = [ 47984 47989 47990 48010 ];

# ...and core/networking.nix is the single place that turns every such
# declaration into interface-scoped rules on host.network.lanInterface.
```

The same pattern carries `unfree` package names and `persist` paths. Note the trap: a
quirk emitted from a **user-scope** aspect only reaches the host if an expose policy is
registered for it in `den.schema.user.includes` - without one it is discarded silently,
with no error. `apps.sync.syncthing` is included at user scope, so its ports depend on exactly
that, and [modules/flake/checks.nix](modules/flake/checks.nix) asserts they arrive.

### The standalone home, and why it exists.

[den/homes.nix](modules/den/homes.nix) declares `den.homes.x86_64-linux.tomwrw`: the same
user aspect both machines use, evaluated with no NixOS underneath it. `nix build
.#homeConfigurations.tomwrw.activationPackage` produces a home-manager generation that
would work on someone else's Ubuntu, and CI evaluates it on every push.

It is not there because I run a non-NixOS machine today. It is there because everything
under `modules/megadots/` claims to describe an *application* rather than my fleet, and the
way that claim rots is silent. den drops a class module whose scope arguments it cannot
supply, and reads a bare function at an aspect path as parametric over scope - so an aspect
that grows a dependency on a host doesn't fail, it just stops contributing, and only in the
context that lacks a host.

That is not hypothetical; building this target found one immediately.
[apps/shell/zsh.nix](modules/megadots/apps/shell/zsh.nix) opened with `{ host, ... }:` so two
aliases could run `nixos-rebuild --flake .#<name>`. Thirty-odd portable aliases, `fzf`,
completion and `dotDir` were all being discarded outside a host, silently, for the sake of
those two. They now come from [core/nix.nix](modules/megadots/core/nix.nix) via
`provides.to-users`, which is host scope and can name the machine honestly.

The `homes` check in [checks.nix](modules/flake/checks.nix) guards the rest. Its sharpest
assertion reads `programs.fzf.enable` rather than `programs.zsh.enable`, because zsh is
turned on by `den.batteries.user-shell` and stays true even when the aspect that *configures*
the shell has vanished - a check on it would have passed throughout the bug above.

### Deliberate Nix settings.

[core/nix.nix](modules/megadots/core/nix.nix) sets two options that are worth calling out explicitly, as they are security concerns I have made with my config:

- `nix.settings.trusted-users = [ "root" "@wheel" ]` - lets any `wheel` member build/substitute arbitrary derivations and push closures via `nixos-rebuild --target-host`. This is a single-admin-LAN trade-off: fine for me as the sole admin of the fleet, but not something you might want to carry into a multi-user or shared-admin setup without consideration.
- `nix.settings.allow-import-from-derivation = true` - required because Stylix's base16 scheme reader does an IFD (`readFile`s a YAML out of the `base16-schemes` derivation at eval time). Without it, evaluation fails outright; it is not optional given my current Stylix setup. I may look at this in the future, but for now, Stylix theming is worth the risk to me.

### Known trade-offs.

Things that are deliberate rather than missed, so you can judge whether they suit you:

- **Stylix is applied through Home Manager only.** The NixOS module is not imported, so
  GDM's login screen, the TTY palette, plymouth and the system fontconfig are unthemed,
  and `stylix.fonts`/`stylix.cursor` are unset - the desktop renders in Stylix's DejaVu
  defaults even though [fonts.nix](modules/megadots/desktop/fonts.nix) installs rather more
  than that. Wiring in `stylix.nixosModules.stylix` would fix all of it.
- **LAN-scoped firewall rules are weaker on a laptop.** Every port is opened on
  `host.network.lanInterface` rather than globally, which is a real improvement on a
  desktop. On `flatmate`, that interface is the Wi-Fi adapter, so it is the same interface
  at home and in a cafe - SSH and Syncthing are reachable on any network it joins. Source
  subnet matching (which needs the nftables backend) is the actual fix.
- **`trusted-users` includes `@wheel`, on a host that signs its own boot chain.** The two
  entries above compose: a trusted user can get arbitrary content into the store, and
  `endgame` is the machine that then signs whatever it boots with its Secure Boot key.
- **A third-party binary cache supplies that host's kernel.**
  [core/linux-kernel.nix](modules/megadots/core/linux-kernel.nix) trusts
  `attic.xuyh0120.win/lantian` for prebuilt CachyOS kernels, and CI trusts the same key.
  It composes with the point above: a compromised cache could hand `endgame` a kernel that
  its own Secure Boot chain would then sign and boot without complaint. Accepted so that a
  zen4 LTO kernel does not have to be compiled locally on every bump.
- **Retired host keys are still in git history, and the payloads behind them are not
  rotated.** `keys/{endgame,flatmate,spectre}.enc` were committed in `5da3b57` and removed
  in `9ac96f5`. They are host age identities wrapped under my *user* age identity. Every
  one of those identities has since been rotated, so the files are useless on their own -
  but they are a chain, not a single file: the retired user key would decrypt them, those
  host keys would decrypt the historical `secrets/*.yaml` blobs, and those still hold the
  values in use today (my password hash and the Syncthing key/cert/GUI password). Closing
  it properly means rotating those payloads, not the wrapping keys. I have chosen to
  document it rather than re-pair the fleet; if you fork this pattern, rotate the payloads
  the first time you rotate an identity.
- **Real hardware serials are in the roster.** `disk.id` in [den/hosts.nix](modules/den/hosts.nix)
  carries the NVMe serial of each machine. `/dev/disk/by-id/` is the correct stable
  identifier - disko partitions on it, and an invariant in
  [checks.nix](modules/flake/checks.nix) enforces the prefix - so it cannot come from sops,
  which is decrypted far too late to place a partition. A serial is an identifier, not a
  credential; the realistic cost is that it fingerprints the hardware.
- **The NAS address is a literal LAN IP.** `megadots.externalPeers` in
  [den/hosts.nix](modules/den/hosts.nix) pins `tcp://10.20.1.3:20978`. A name would read better, but `home.arpa` is only a search
  domain here - nothing serves DNS records for it, so `nas.home.arpa` does not resolve and
  the pinned address is what actually makes the pairing reliable. It discloses one RFC1918
  subnet and a non-default port.

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
just check                # build both hosts + fleet invariants + roster checks
just fmt                  # nixfmt + deadnix + statix via treefmt
just update               # nix flake update
just gc                   # collect garbage older than 30 days
just enroll-fido2 endgame # add the inserted token to the LUKS header
just secrets-edit secrets/users/tomwrw.yaml
just secrets-updatekeys   # re-sync sops recipients after editing .sops.yaml
```

`just check` is the one worth knowing about: it builds both hosts, then asserts a set of
fleet invariants - no globally-open firewall ports, `/persist` marked `neededForBoot`,
host keys under `/persist`, `/` actually on the rolled-back `root` subvolume with its
rollback service present, the bootloader bounded and its editor disabled, hardening
kernel params actually present, and user-scope firewall quirks reaching the host.

CI runs the same checks, but splits them: the evaluation-only ones run on every push,
while the full host builds run on `main`, pull requests and manual dispatch. `flatmate`
compiles a patched linux-surface kernel that no public cache serves, so its build is
cached across runs by store path rather than repeated - see
[check.yml](.github/workflows/check.yml).

### Bootstrapping a host from scratch.

Run `just check-bootstrap <name>` at any point - it verifies every one of the following
and refuses to call the host ready until they are all in place. `just deploy` runs it
first, so a missing file fails *before* anything is partitioned rather than half way
through.

1. **USB key material**, at the layout the `deploy` recipe expects. Note the SSH keys as
   well as the age keys - `deploy` seeds all of them and aborts on any that is missing:

   ```
   <usb>/hosts/<hostname>/age.txt          # host age key  -> /persist/var/lib/sops-nix/key.txt
   <usb>/users/<username>/age.txt          # user age key  -> /persist/home/<user>/.config/sops/age/keys.txt
   <usb>/users/<username>/id_ed25519{,.pub}
   <usb>/users/<username>/id_ed25519_sk_primary{,.pub}    # FIDO2 handles; useless without
   <usb>/users/<username>/id_ed25519_sk_backup{,.pub}     # the physical token
   ```

   The `usb` path itself is a variable at the top of the [justfile](justfile).

2. **A `creation_rules` block for the new host** in [.sops.yaml](.sops.yaml) - one per
   secrets file, listing its recipients. Adding a key to the recipient list is not enough;
   without its own rule the host's secrets are encrypted to nobody. Then run
   `just secrets-updatekeys`.
3. **`secrets/hosts/<name>.yaml`** with at least `users/<user>/password`. Evaluation
   interpolates this filename from the hostname, so a missing file fails the build.
4. **`syncthing/<name>/{key,cert,guiPassword}` in `secrets/users/<user>.yaml`** - the
   syncthing secrets are keyed by *host* but live in the *user* file
   ([apps/sync/syncthing.nix](modules/megadots/apps/sync/syncthing.nix)). Miss these and the host
   builds fine, then Home Manager activation fails on the new machine.
5. **The roster entry** in [modules/den/hosts.nix](modules/den/hosts.nix): disk id (a
   stable `/dev/disk/by-id/` path), swap size, LAN interface name from `ip -br link`, and
   the Syncthing device id. `just check` validates all four.
6. **`modules/hosts/<name>/`** with a `default.nix` listing the roles it takes and a
   `_hardware.nix` from `nixos-generate-config`.

Then boot the target from a NixOS installer ISO, set a password for the `nixos` user so
SSH works, and run `just deploy <name>`. nixos-anywhere partitions with disko, seeds the
keys and installs.

### Adapting this for yourself.

Fork it, then: replace `modules/users/` and `modules/hosts/` with your own, empty the
roster in `modules/den/hosts.nix`, regenerate `.sops.yaml` with your own age keys, and
replace `assets/` (the wallpapers are not covered by this repo's licence - see
[LICENSE](LICENSE)). The parts worth keeping are `modules/megadots/`,
`modules/den/quirks.nix` and `modules/flake/checks.nix` - no aspect names a host or a
user, so they port across unchanged.

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
