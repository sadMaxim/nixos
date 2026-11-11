# Host configurations: full and lightweight profiles

This flake exposes **four** NixOS configurations — two machines, two
profiles each:

| Output | Host | Contents |
| --- | --- | --- |
| `nixos` | old host (Intel) | The full configuration. Neovim (`nixvim`) and the AI coding CLIs (`llm-agents`: `claude-code`, `codex`, `opencode`, `pi`, `mcode`) are installed. |
| `nixos-lightweight` | old host (Intel) | The same system, **minus** the `nixvim` and `llm-agents` packages. |
| `nixos-new-laptop` | new laptop (AMD) | The full configuration of the new laptop. |
| `nixos-new-laptop-lightweight` | new laptop (AMD) | The same laptop configuration **minus** the `nixvim` and `llm-agents` packages, using the official NixOS binary cache only. |

Everything else is identical in the two profiles of a host: system modules,
`amneziawg-vdsina`, `throne`, `sing-box`, `tmux`, `kitty`, `waybar`,
`hyprland`, `programming`, hostname maps, IPv6 preference and the whole
`home-manager.users.maxim` block.

## Shared configuration and host modules

`configuration.nix` is **hardware agnostic**: it contains no disk UUID, no
LUKS device, no `system.stateVersion` and no CPU or graphics specifics.
Everything that belongs to exactly one machine lives in a host module:

```
hosts/
├── old-host/
│   ├── default.nix                # imports ../../hardware-configuration.nix
│   └── ...
└── new-laptop/
    ├── default.nix                # imports ./hardware-configuration.nix
    ├── hardware-configuration.nix  # generated on the laptop itself
    └── lightweight-cache.nix       # official cache only (lightweight profile)
```

* `hosts/old-host` imports the `hardware-configuration.nix` in the repository
  root (the old, Intel machine), declares its encrypted swap container
  `luks-67f943c7-…`, its `system.stateVersion` and its Intel VA-API driver.
* `hosts/new-laptop` imports its own `hardware-configuration.nix` (generated
  on the laptop with `nixos-generate-config`), declares its encrypted swap
  container `luks-bf4de334-…`, its `system.stateVersion` and the SSH server
  the laptop is administered with (password authentication, port open in the
  firewall).

`modules/default.nix` builds every configuration from **one** module list.
The host module and the profile are handed to it:

```nix
mkSystem = hostModule: lightweight: inputs.nixpkgs.lib.nixosSystem { … };
…
nixos                        = mkSystem ../hosts/old-host   false;
nixos-lightweight            = mkSystem ../hosts/old-host   true;
nixos-new-laptop             = mkSystem ../hosts/new-laptop false;
nixos-new-laptop-lightweight = mkSystem ../hosts/new-laptop true;
```

## How the difference between the profiles is implemented

The profile is handed to the modules through the `lightweight` special
argument — `false` for the full profile, `true` for the `-lightweight`
profile. `modules/home.nix` uses that flag:

- `lib.optionals (!lightweight)` around the `./agents.nix` and
  `inputs.nixvim.homeModules.nixvim` imports, so neither module is loaded —
  and therefore never evaluated — in a lightweight profile;
- `lib.optionalAttrs (!lightweight)` around the `programs.nixvim` options, so
  options that only exist when the nixvim home module is imported are never
  set in a lightweight profile.

The flake **inputs** (`nixvim`, `llm-agents`) are still part of the flake, so
they are still fetched when the flake is evaluated — the flake has a single
lock file. A lightweight profile only skips the **build and the install** of
the packages that come from them.

The binary caches are not part of the profile, but of the host: the full
profiles keep the caches configured in `configuration.nix` (official,
nix-community, numtide, hyprland), the lightweight profile of the new
laptop replaces them with the official cache only
(`hosts/new-laptop/lightweight-cache.nix`). The flake itself does not set a
flake-wide `nixConfig` any more.

## Switching between the profiles and the hosts

Run these from the directory that contains `flake.nix` (on the installed
system that is `/etc/nixos`):

```sh
# old host
sudo nixos-rebuild switch --flake .#nixos
sudo nixos-rebuild switch --flake .#nixos-lightweight

# new laptop
sudo nixos-rebuild switch --flake .#nixos-new-laptop
sudo nixos-rebuild switch --flake .#nixos-new-laptop-lightweight
```

Switching profiles rebuilds the affected packages; switching back
re-installs Neovim and the coding agents.

**No ISO is built by any of the profiles.** Nothing in this repository builds
an installer image, and no ISO is shipped. Install NixOS from the official
installation media (`nixos.org/download`) and then point the installer at
this configuration.

## Installing on the new laptop

The hardware configuration of the new laptop is already part of this
repository (`hosts/new-laptop/hardware-configuration.nix`), so **no UUID has
to be edited by hand**: the named outputs `nixos-new-laptop` and
`nixos-new-laptop-lightweight` use the disks, the LUKS devices and the swap
device of that machine.

On the laptop the configuration has to live in `/etc/nixos`:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos-new-laptop
# or, without nixvim and the coding agents:
sudo nixos-rebuild switch --flake /etc/nixos#nixos-new-laptop-lightweight
```

If the laptop is reinstalled from scratch, generate a fresh hardware
configuration on it and replace the checked-in one with it:

```sh
sudo nixos-generate-config --root /mnt
sudo mv /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
```

The generated file replaces `hosts/new-laptop/hardware-configuration.nix`
(and nothing else — the shared `configuration.nix` does not contain a single
UUID of any machine).

## Installing on a machine that is not known to the flake yet

Create a host module next to the existing ones, put the generated
`hardware-configuration.nix` next to it and add the two outputs to
`modules/default.nix`:

```sh
sudo nixos-generate-config --root /mnt
sudo mv /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
```

```nix
# modules/default.nix
nixos-<host>             = mkSystem ../hosts/<host> false;
nixos-<host>-lightweight = mkSystem ../hosts/<host> true;
```

The shared `configuration.nix` stays untouched.

## Installing the full configuration on a fresh machine

Clone the repository into the target's `/etc/nixos` — that is where the
configuration has to live for the installed system:

```sh
git clone <this repo> /tmp/nixos-config
sudo cp -a /tmp/nixos-config/. /mnt/etc/nixos/
sudo nixos-install --flake path:/mnt/etc/nixos#nixos
```

`nixos-install` installs into `/mnt` by default. `--flake` does **not**
require a Git repository — any directory with a `flake.nix` works. `path:`
makes Nix use the whole directory, so the freshly copied
`hardware-configuration.nix` is used even though the checkout is a Git
repository (without `path:`, Nix copies only Git-tracked files). The flake
inputs are fetched from GitHub at install time.

Use `#nixos-lightweight` instead of `#nixos` to install the profile without
nixvim and the coding agents.

## After the first boot

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos
# or the lightweight profile
sudo nixos-rebuild switch --flake /etc/nixos#nixos-lightweight
```
