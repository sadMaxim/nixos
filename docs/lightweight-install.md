# Full and lightweight root configurations

This flake exposes **two** NixOS configurations built from the same modules:

| Output | Contents |
| --- | --- |
| `nixos` | The full configuration. Neovim (`nixvim`) and the AI coding CLIs (`llm-agents`: `claude-code`, `codex`, `opencode`, `pi`, `mcode`) are installed. |
| `nixos-lightweight` | The same system, **minus** the `nixvim` and `llm-agents` packages. |

Everything else is identical in both profiles: system modules,
`amneziawg-vdsina`, `throne`, `sing-box`, `tmux`, `kitty`, `waybar`,
`hyprland`, `programming`, hostname maps, IPv6 preference, phone control and
the whole `home-manager.users.maxim` block.

## How the difference is implemented

`modules/default.nix` builds both configurations from **one** module list and
passes a `lightweight` special argument — `false` for `nixos`, `true` for
`nixos-lightweight`. `modules/home.nix` uses that flag:

- `lib.optionals (!lightweight)` around the `./agents.nix` and
  `inputs.nixvim.homeModules.nixvim` imports, so neither module is loaded —
  and therefore never evaluated — in the lightweight profile;
- `lib.optionalAttrs (!lightweight)` around the `programs.nixvim` options, so
  options that only exist when the nixvim home module is imported are never
  set in the lightweight profile.

The flake **inputs** (`nixvim`, `llm-agents`) are still part of the flake, so
they are still fetched when the flake is evaluated — the flake has a single
lock file. The lightweight profile only skips the **build and the install** of
the packages that come from them.

## Switching between the two profiles

Run these from the directory that contains `flake.nix` (on the installed
system that is `/etc/nixos`):

```sh
# full configuration
sudo nixos-rebuild switch --flake .#nixos

# lightweight configuration (no nixvim, no coding agents)
sudo nixos-rebuild switch --flake .#nixos-lightweight
```

Switching profiles rebuilds the affected packages; switching back
re-installs Neovim and the coding agents.

**No ISO is built by either profile.** Nothing in this repository builds an
installer image, and no ISO is shipped. Install NixOS from the official
installation media (`nixos.org/download`) and then point the installer at
this configuration.

## Installing on a new machine (hardware UUIDs)

### 1. Generate a hardware configuration on the new machine

The `hardware-configuration.nix` checked into this repository contains the
**old** machine's disk UUIDs (`fileSystems."/"`, the LUKS device and
`swapDevices`) and will not match the new machine's disks. Do not use it
as-is.

Generate a fresh one in the installer environment, with the target mounted
at `/mnt`. `--root /mnt` makes `nixos-generate-config` write into the mounted
target instead of the installer system:

```sh
sudo nixos-generate-config --root /mnt
sudo mv /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
```

`configuration.nix` comes from this repository — keep only the generated
`hardware-configuration.nix`; it is copied into the checkout in step 2.

`configuration.nix` hard-codes one more UUID of the old machine:

```nix
boot.initrd.luks.devices."luks-67f943c7-079c-472e-9335-0d315c671c40".device = "/dev/disk/by-uuid/67f943c7-079c-472e-9335-0d315c671c40";
```

Delete that line — the generated `hardware-configuration.nix` already declares
the new machine's LUKS device — or replace the UUID with the new one (the
encrypted swap/root container UUID, e.g. from `cryptsetup luksUUID /dev/…` or
`lsblk -f` in the installer). The same goes for any other old swap or root
UUID in `configuration.nix`: the generated hardware configuration provides the
ones that belong to the new machine.

### 2. Install

Clone the repository into the target's `/etc/nixos` — that is where the
configuration has to live for the installed system — and copy the generated
hardware configuration over the checked-in one *after* the clone:

```sh
git clone <this repo> /tmp/nixos-config
sudo cp -a /tmp/nixos-config/. /mnt/etc/nixos/
sudo cp /tmp/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix
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

### 3. After the first boot

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos
# or the lightweight profile
sudo nixos-rebuild switch --flake /etc/nixos#nixos-lightweight
```
