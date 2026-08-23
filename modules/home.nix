{ config, lib, pkgs, inputs, home-manager, nixpkgs-unstable, ... }:
{
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.extraSpecialArgs = { inherit nixpkgs-unstable inputs; };
  
  home-manager.users.maxim = { pkgs, nixpkgs-unstable, inputs, ... }:
  let
    unstable = nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    pgwebWrapped = pkgs.writeShellScriptBin "pgweb" ''
      set -euo pipefail
      url="''${PGWEB_URL:-postgres://maxim@/maxim?host=/run/postgresql}"
      exec ${pkgs.pgweb}/bin/pgweb \
        --bind 127.0.0.1 --listen 8081 \
        --url "$url" "$@"
    '';
    pychessWrapped = pkgs.symlinkJoin {
      name = "pychess";
      paths = [ pkgs.pychess ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pychess \
          --prefix PATH : ${lib.makeBinPath [ pkgs.stockfish ]}
      '';
    };
    sshUtils = pkgs.writeShellApplication {
      name = "ssh_utils";
      runtimeInputs = [
        pkgs.git
        pkgs.inotify-tools
        pkgs.openssh
        pkgs.python3
        pkgs.rsync
      ];
      text = ''
        exec ${pkgs.python3}/bin/python ${./ssh_utils.py} "$@"
      '';
    };
    seshHere = pkgs.writeShellApplication {
      name = "sesh-here";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.gnused
        pkgs.sesh
        pkgs.tmux
      ];
      text = ''
        set -euo pipefail

        dir="''${1:-$PWD}"
        dir="$(realpath "$dir")"

        clean_name() {
          printf '%s' "$1" \
            | sed -E 's#[/:[:space:]]+#-#g; s#[^A-Za-z0-9_.@-]#-#g; s#-+#-#g; s#^-##; s#-$##'
        }

        if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          root="$(git -C "$dir" rev-parse --show-toplevel)"
          repo="$(basename "$root")"
          branch="$(git -C "$dir" branch --show-current)"
          if [ -z "$branch" ]; then
            branch="$(git -C "$dir" rev-parse --short HEAD)"
          fi
          name="$(clean_name "$repo@$branch")"
        else
          name="$(clean_name "$(basename "$dir")")"
        fi

        [ -n "$name" ] || name="home"

        base_name="$name"
        suffix=1
        while tmux has-session -t "=$name" 2>/dev/null; do
          name="$base_name-$suffix"
          suffix=$((suffix + 1))
        done

        tmux new-session -d -s "$name" -c "$dir"

        if [ -n "''${TMUX:-}" ]; then
          exec sesh connect -s "$name"
        else
          exec sesh connect "$name"
        fi
      '';
    };
    sc = pkgs.writeShellApplication {
      name = "sc";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.sesh
        pkgs.zoxide
      ];
      text = ''
        set -euo pipefail

        target="''${1:-$PWD}"

        if [ -d "$target" ]; then
          dir="$(realpath "$target")"
          exec ${seshHere}/bin/sesh-here "$dir"
        fi

        if dir="$(zoxide query -- "$target" 2>/dev/null)"; then
          exec ${seshHere}/bin/sesh-here "$dir"
        fi

        # Fall back to normal sesh behavior for existing session/config names.
        if [ -n "''${TMUX:-}" ]; then
          exec sesh connect -s "$@"
        else
          exec sesh connect "$@"
        fi
      '';
    };
    # Toggle gpu-screen-recorder: full-screen start/stop, 15 fps / medium quality,
    # tiny file in /tmp, absolute path copied (as plain text) to the clipboard on stop.
    # Bound to F11 in modules/hyprland.nix.
    #
    # Notes:
    #   * gsr is launched via `nohup setsid … </dev/null >"$LOG" 2>&1 & disown` so
    #     it outlives this script (otherwise the parent's SIGHUP kills gsr a fraction
    #     of a second after F11, which the user perceives as "dies on mouse click").
    #   * We never use a basename-only kill (pkill -x) because it would also match
    #     the replay daemon (`-mf yes`), which cannot coexist with a fresh recording
    #     on the same encoder. All signalling goes through the pidfile at
    #     /tmp/gsr-toggle.pid, which is the F11 process only.
    #   * A flock-based mutex prevents races if F11 is autorepeated or double-tapped.
    #   * The always-on replay daemon is intentionally not auto-started from
    #     modules/hyprland.nix exec-once; see that file for the manual start line.
    gsrToggle = pkgs.writeShellApplication {
      name = "gsr-toggle";
      runtimeInputs = with pkgs; [
        coreutils
        findutils
        gawk
        procps
        util-linux
        wl-clipboard
        libnotify
        gpu-screen-recorder
      ];
      text = ''
        set -euo pipefail

        # Mutex against rapid double-press (e.g. autorepeat F11).
        exec 9>/tmp/gsr-toggle.lock
        if ! flock -n 9; then
          echo "gsr-toggle: another instance running" >&2
          exit 0
        fi

        OUT="/tmp"
        PIDFILE="/tmp/gsr-toggle.pid"
        LOG="/tmp/gsr-toggle.log"

        # Stop branch: pidfile exists and points at a live gsr process.
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
          PID="$(cat "$PIDFILE")"
          kill -INT "$PID"
          for _ in $(seq 1 25); do
            sleep 0.2
            kill -0 "$PID" 2>/dev/null || break
          done
          latest="$(find "$OUT" -maxdepth 1 -type f -name 'recording-*.mp4' -printf '%T@ %p\n' 2>/dev/null \
            | sort -rn \
            | head -1 \
            | awk '{$1=""; sub(/^ /,""); print}')"
          if [ -n "''${latest:-}" ]; then
            abs="$(realpath -- "$latest")"
            # Copy the plain absolute path to the clipboard (wl-copy defaults to
            # text/plain), so the user can paste it into a terminal, editor, chat,
            # etc. file:// URI was rejected: it forces text/uri-list semantics that
            # confuse most text-paste targets.
            printf '%s' "$abs" | wl-copy
            sz="$(du -h "$latest" 2>/dev/null | cut -f1)"
            notify-send -a "gpu-screen-recorder" "Recording stopped" "$(basename "$latest") (''${sz:-?}) → clipboard" || true
          else
            notify-send -a "gpu-screen-recorder" "Recording stopped" "No file found in $OUT" || true
          fi
          rm -f "$PIDFILE"
        else
          # Stale pidfile recovery: a previous run crashed without cleanup.
          [ -f "$PIDFILE" ] && rm -f "$PIDFILE"

          # Start branch: kick off a fully detached gsr instance and remember its PID.
          ts="$(date +%Y%m%d-%H%M%S)"
          file="$OUT/recording-$ts.mp4"
          : > "$LOG"
          nohup setsid gpu-screen-recorder \
            -w screen -f 15 -c mp4 -q medium \
            -a default_output \
            -o "$file" \
            </dev/null >"$LOG" 2>&1 & disown
          PID=$!
          printf '%s\n' "$PID" > "$PIDFILE"

          for _ in $(seq 1 25); do
            sleep 0.2
            kill -0 "$PID" 2>/dev/null && break
          done

          if kill -0 "$PID" 2>/dev/null; then
            notify-send -a "gpu-screen-recorder" "Recording started" "$file" || true
          else
            rm -f "$PIDFILE"
            notify-send -a "gpu-screen-recorder" "Recording failed to start" "Run gpu-screen-recorder in a terminal" || true
            exit 1
          fi
        fi
      '';
    };
    # Save the last 30s from the gpu-screen-recorder replay daemon to disk + clipboard.
    # Bound to SHIFT+Print in modules/hyprland.nix.
    gsrSaveReplay = pkgs.writeShellApplication {
      name = "gsr-save-replay";
      runtimeInputs = with pkgs; [
        coreutils
        findutils
        gawk
        procps
        wl-clipboard
        libnotify
      ];
      text = ''
        set -euo pipefail

        REPLAY_DIR="$HOME/Videos/Replays"

        if ! pgrep -x gpu-screen-recorder >/dev/null; then
          notify-send -a "gpu-screen-recorder" "Replay daemon not running" "See ~/.local/share/gsr-replay.log"
          exit 1
        fi

        pkill -USR1 -x gpu-screen-recorder
        sleep 0.5

        # Newest .mp4 by mtime, path may contain spaces
        latest="$(find "$REPLAY_DIR" -type f -name '*.mp4' -printf '%T@ %p\n' 2>/dev/null \
          | sort -rn \
          | head -1 \
          | awk '{$1=""; sub(/^ /,""); print}')"

        if [ -n "''${latest:-}" ]; then
          printf '%s' "$latest" | wl-copy
          notify-send -a "gpu-screen-recorder" "Replay saved" "$(basename "$latest") → clipboard"
        else
          notify-send -a "gpu-screen-recorder" "Replay save failed" "No file produced"
          exit 1
        fi
      '';
    };
    neonctl = pkgs.buildNpmPackage {
      pname = "neonctl";
      version = "2.22.0";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/neonctl/-/neonctl-2.22.0.tgz";
        hash = "sha256-NPoX/bBM6GntHmLQuXcJU99tpyWvC+rVwriBB0/GZsQ=";
      };
      postPatch = ''
        cp ${./neonctl-package-lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-/GVQPbJBESkadS3CDzijAbu96BVjSnM7DwxSwysOn8k=";
      dontNpmBuild = true;
      installPhase = ''
        mkdir -p $out/lib/node_modules
        cp -r . $out/lib/node_modules/neonctl
        mkdir -p $out/bin
        ln -s $out/lib/node_modules/neonctl/cli.js $out/bin/neonctl
        ln -s $out/bin/neonctl $out/bin/neon
      '';
      meta = with pkgs.lib; {
        description = "CLI tool for Neon Serverless Postgres";
        homepage = "https://neon.tech/docs/reference/cli-overview";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    };
    # Source script for the `sesh` television cable channel.  Prints one
    # line per tmux session, grouped by repo (substring before the first `@`)
    # and color-coded so the picker is readable at a glance:
    #
    #   <color>● collect<reset>@worktree-collect-claude  <dim>~/projects/collect<reset>
    #
    # Groups are sorted alphabetically and each group gets a stable color
    # from a fixed palette.  Combined with `no_sort = true` on the channel,
    # tv preserves the emitted order so all sessions of one repo stay
    # together.
    tvSeshSource = pkgs.writeShellApplication {
      name = "tv-sesh-source";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gawk
        pkgs.tmux
      ];
      text = ''
        set -euo pipefail

        # Override with SESHTV_ACTIVE_THRESHOLD (seconds).  Active = running
        # command isn't a shell OR the shell produced visible activity in the
        # last threshold seconds.
        ACTIVE_THRESHOLD="''${SESHTV_ACTIVE_THRESHOLD:-10}"

        RESET=$'\033[0m'
        DIM=$'\033[2m'

        # 11 visually distinct colors, cycled by group index (alphabetical).
        COLORS=(
          $'\033[36m'  # cyan
          $'\033[35m'  # magenta
          $'\033[33m'  # yellow
          $'\033[34m'  # blue
          $'\033[32m'  # green
          $'\033[91m'  # bright red
          $'\033[92m'  # bright green
          $'\033[93m'  # bright yellow
          $'\033[94m'  # bright blue
          $'\033[95m'  # bright magenta
          $'\033[96m'  # bright cyan
        )
        NC=''${#COLORS[@]}

        now=$(date +%s)

        tmp=$(mktemp)
        trap 'rm -f "$tmp" "$tmp.idx"' EXIT

        # Phase 1 — collect one row per session: group \t mark \t name \t path.
        # Keep the full session name instead of a possibly-empty `rest` field:
        # Bash collapses adjacent IFS whitespace when reading tab-delimited rows,
        # which would turn `name<TAB><TAB>path` into `name<TAB>path`.
        tmux list-sessions -F "#{session_activity}|#{pane_current_command}|#{session_name}|#{pane_current_path}" \
          | LC_ALL=C sort -t '|' -k3 \
          | while IFS='|' read -r activity command name path; do
              [ -n "$name" ] || continue
              diff=$((now - activity))
              case "$command" in
                bash|zsh|fish|sh|nu|dash|ash|ksh|csh|tcsh|"")
                  if [ "$diff" -lt "$ACTIVE_THRESHOLD" ]; then
                    mark=$'\xe2\x97\x8f'  # ●
                  else
                    mark=$'\xe2\x97\x8b'  # ○
                  fi
                  ;;
                *) mark=$'\xe2\x97\x8f' ;;  # ●
              esac
              if [[ "$name" == *@* ]]; then
                group="''${name%%@*}"
              else
                group="$name"
              fi
              short_path="''${path/#$HOME/\~}"
              printf '%s\t%s\t%s\t%s\n' "$group" "$mark" "$name" "$short_path" >> "$tmp"
            done

        # Phase 2 — pick a color index for each unique group, alphabetical.
        awk -F'\t' '{print $1}' "$tmp" | sort -u | awk -v NC="$NC" '{print (NR-1)%NC "\t" $0}' > "$tmp.idx"

        # Phase 3 — emit colored, grouped lines.
        declare -A group_color=()
        while IFS=$'\t' read -r idx group; do
          group_color["$group"]="''${COLORS[$idx]}"
        done < "$tmp.idx"

        # Re-sort sessions by group name so all of one repo cluster together.
        sort -t $'\t' -k1,1 "$tmp" -o "$tmp"

        while IFS=$'\t' read -r group mark name path; do
          color="''${group_color[$group]:-$RESET}"
          if [[ "$name" == *@* ]]; then
            rest="''${name#*@}"
            # <color>● <color>collect<reset>@worktree-collect-claude  <dim>~/projects/collect<reset>
            #   mark          group colored          branch uncolored           path dim
            printf '%s%s %s%s%s@%s  %s%s%s\n' \
              "$color" "$mark" "$color" "$group" "$RESET" "$rest" \
              "$DIM" "$path" "$RESET"
          else
            printf '%s%s %s%s%s  %s%s%s\n' \
              "$color" "$mark" "$color" "$group" "$RESET" \
              "$DIM" "$path" "$RESET"
          fi
        done < "$tmp"
      '';
    };
    # Smart-rename all tmux sessions based on cwd + foreground command.
    # Same logic that used to live inside the ctrl-r branch of the old
    # sesh-tv wrapper; pulled out so the cable channel can call it as a
    # `fork` action and the picker stays open while renaming runs.
    seshTvRename = pkgs.writeShellApplication {
      name = "sesh-tv-rename";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.gnused
        pkgs.sesh
        pkgs.tmux
      ];
      text = ''
        set -euo pipefail

        clean_name() {
          printf '%s' "$1" \
            | sed -E 's#[/:[:space:]]+#-#g; s#[^A-Za-z0-9_.@-]#-#g; s#-+#-#g; s#^-##; s#-$##'
        }

        smart_name() {
          dir="$1"
          cmd="$2"

          if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            root="$(git -C "$dir" rev-parse --show-toplevel)"
            repo="$(basename "$root")"
            branch="$(git -C "$dir" branch --show-current)"
            if [ -z "$branch" ]; then
              branch="$(git -C "$dir" rev-parse --short HEAD)"
            fi
            base="$repo@$branch"
          else
            base="$(basename "$dir")"
          fi

          case "$cmd" in
            bash|zsh|fish|sh|tmux|nu) clean_name "$base" ;;
            *) clean_name "$base-$cmd" ;;
          esac
        }

        unique_name() {
          base="$1"
          old="$2"
          name="$base"
          suffix=1
          while tmux has-session -t "=$name" 2>/dev/null && [ "$name" != "$old" ]; do
            name="$base-$suffix"
            suffix=$((suffix + 1))
          done
          printf '%s\n' "$name"
        }

        sesh list -t | while IFS= read -r session; do
          [ -n "$session" ] || continue
          dir="$(tmux display-message -p -t "=$session:" '#{pane_current_path}' 2>/dev/null || true)"
          cmd="$(tmux display-message -p -t "=$session:" '#{pane_current_command}' 2>/dev/null || true)"
          [ -n "$dir" ] || continue
          [ -n "$cmd" ] || cmd="shell"
          new_name="$(unique_name "$(smart_name "$dir" "$cmd")" "$session")"
          [ -n "$new_name" ] || continue
          [ "$new_name" = "$session" ] && continue
          tmux rename-session -t "=$session" "$new_name"
        done
      '';
    };
    # Thin wrapper that opens the `sesh` television cable channel.  All
    # coloring / grouping / preview / keybindings live in
    # ~/.config/television/cable/sesh.toml (managed by home-manager via
    # xdg.configFile below) so the picker is reusable from anywhere with
    # just `tv sesh`.
    seshTv = pkgs.writeShellApplication {
      name = "sesh-tv";
      runtimeInputs = [
        pkgs.television
      ];
      text = ''
        exec tv sesh
      '';
    };
    # Alphabetical session cycler used by tmux M-h / M-l / M-t bindings.
    # next/prev: step forward/backward through sessions sorted with LC_ALL=C,
    # wrapping at the ends. toggle: jump to the previously active session
    # (2-state, like the old Alt+h behavior).
    tmuxCycle = pkgs.writeShellApplication {
      name = "tmux-cycle";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.tmux
      ];
      text = ''
        set -euo pipefail

        direction="''${1:-}"

        case "$direction" in
          toggle)
            exec tmux switch-client -l
            ;;
          next|prev)
            current="$(tmux display-message -p '#{session_name}')"
            mapfile -t sessions < <(tmux list-sessions -F '#{session_name}' | LC_ALL=C sort)

            n="''${#sessions[@]}"
            [ "$n" -gt 1 ] || exit 0

            idx=-1
            for i in "''${!sessions[@]}"; do
              if [ "''${sessions[$i]}" = "$current" ]; then
                idx=$i
                break
              fi
            done
            [ "$idx" -ge 0 ] || exit 0

            case "$direction" in
              next) target="''${sessions[$(( (idx + 1) % n ))]}" ;;
              prev) target="''${sessions[$(( (idx - 1 + n) % n ))]}" ;;
            esac

            [ "$target" != "$current" ] || exit 0
            exec tmux switch-client -t "$target"
            ;;
          *)
            echo "usage: tmux-cycle {next|prev|toggle}" >&2
            exit 2
            ;;
        esac
      '';
    };
  in {

     home.stateVersion = "25.05";

    # Groq API key is loaded at shell startup from ~/secrets/GROQ_WHISPER.

   home.packages = with pkgs; [
     # Archive extraction utility
     unzip
     # Fast line-oriented regex search tool
     ripgrep
     # Simple, fast alternative to find
     fd
     # Smart tmux session manager
     sesh
     # Fast fuzzy finder used by tmux/sesh popup
     television
     # Create/switch to a smart tmux session for the current directory
     seshHere
     # Short smart sesh connect command: sc <path-or-zoxide-query>
     sc
     # Tmux/sesh popup helper: thin wrapper that opens the `sesh` tv channel
     seshTv
     # Source script for the `sesh` tv cable channel (grouped, color-coded)
     tvSeshSource
     # Smart-rename all tmux sessions based on cwd + foreground command
     # (called by the tv channel's Ctrl-R action)
     seshTvRename
     # Alphabetical tmux session cycler (M-h / M-l / M-t bindings)
     tmuxCycle
     # Terminal file manager
     yazi
     # Distributed version control system
     git
      # Chess engine
      stockfish
      # Wayland-native chess GUI
      pychessWrapped
      # Tray applet for NetworkManager
      networkmanagerapplet
     # Replacement for Dolphin (GNOME Files)
     nautilus
     adwaita-icon-theme  # Essential for icons to work "out of the box"
     # Screen locker for Hyprland Wayland compositor
     hyprlock
     # Wayland clipboard utilities
     wl-clipboard
     # Keyboard-driven pointer tool for Wayland
     wl-kbptr
     # PulseAudio/PipeWire volume control utility
     pwvucontrol
     # Game-streaming client (connect to Sunshine / NVIDIA GameStream hosts)
     moonlight-qt
     # Command-line utility to control screen brightness
     brightnessctl
     # DDC/CI control for monitors
     ddcutil
     # DMI table decoder for hardware information
     dmidecode
      # JavaScript runtime environment
      nodejs
 
       # Process file descriptor lister
      lsof
      # RunPod command-line interface
      runpodctl
      # Neon serverless Postgres CLI
      neonctl
      # Privacy-focused web browser
      brave

     # LibreOffice office suite — Writer (Word .docx/.doc), Calc (Excel),
     # Impress (PowerPoint).  Pulled from stable nixpkgs; `libreoffice-fresh`
     # exists in unstable but tracks the rolling release.
     libreoffice
        # Age encryption tool
        age
      # Image manipulation tool
      imagemagick
      # Throne is provided by the system module at modules/throne/ —
      # it builds upstream Throne 1.2.4 from the .deb, not the stale
      # nixpkgs build. Don't add `throne` here; enable the module via
      # `programs.throne.enable = true` in configuration.nix.
      # See modules/throne/pkgs/throne/default.nix for the derivation.

      ##### ai
      # Groq Whisper STT - speech to text via Groq API (OpenAI-compatible)
      (pkgs.writeShellScriptBin "whisper-grok" ''
        set -euo pipefail
        API_KEY="''${GROQ_API_KEY:-}"
        if [ -z "$API_KEY" ]; then
          echo "Error: GROQ_API_KEY environment variable not set" >&2
          echo "Set it with: export GROQ_API_KEY=your_key" >&2
          exit 1
        fi
        MODEL="''${2:-whisper-large-v3-turbo}"
        curl -s https://api.groq.com/v1/audio/transcriptions \
          -H "Authorization: Bearer $API_KEY" \
          -F "model=$MODEL" \
          -F "file=@$1"
      '')

      ##### ai

      ##### databases
      # Web-based PostgreSQL client
      pgwebWrapped

      ##### ssh tools
      sshUtils
     ##### design
     # 3D creation suite
     blender
     # Wayland screenshot tools
     grim
     slurp
     xvfb-run
     # Desktop notification sender (used by gsr-toggle / gsr-save-replay)
     libnotify
     # Optional GUI for gpu-screen-recorder (codec/quality settings, live preview)
     gpu-screen-recorder-gtk
     # Screen recording helpers bound to Print / SHIFT+Print in modules/hyprland.nix
     gsrToggle
     gsrSaveReplay
    ];

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
     ./programming.nix
     ./agents.nix
      inputs.nixvim.homeModules.nixvim 
   ];
   


    # programs 
    programs = {
      bash = {
        enable = true;
        # Source Groq API key from secrets file at shell startup
        profileExtra = ''
          # Groq Whisper API key
          if [ -f "''${HOME}/secrets/GROQ_WHISPER" ]; then
            export GROQ_API_KEY="$(cat "''${HOME}/secrets/GROQ_WHISPER")"
          fi
        '';
      };
      kitty.enable = true;

      # Throne is on $PATH via home.packages (above). The home-manager
      # `programs.throne` module isn't shipped in the pinned
      # home-manager/release-25.11, so manage settings inside the GUI.
      # Launch with `throne`.
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      # git
      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
       settings.credential.helper = "store";
      };

      nixvim = (import ./nixvim {inherit pkgs;}) // {
        defaultEditor = true;
        nixpkgs.useGlobalPackages = true;
        enable = true;
      };

      fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = false;
        defaultCommand = "fd --type f";
      };

      zoxide = {
        enable = true;
        enableBashIntegration = true;
      };

    };

    # Television cable channel for tmux sessions.  Lets `tv sesh` open the
    # picker with grouped, color-coded rows, a live preview of the selected
    # session's pane, and Enter / Ctrl-D / Ctrl-R keybindings for switch /
    # kill / smart-rename.  All visual rules and grouping live here so the
    # picker is reusable from anywhere with just `tv sesh`.
    xdg.configFile."television/cable/sesh.toml".text = ''
      [metadata]
      name = "sesh"
      description = "Tmux sessions, grouped by repo and color-coded"
      requirements = ["tmux", "television"]

      [source]
      command = "tv-sesh-source"
      # Each line is ANSI-formatted: <color>● collect<reset>@worktree-...  <dim>~/path<reset>.
      # `no_sort` keeps the emitted order so all sessions of one repo cluster together;
      # `frecency = false` disables match-quality re-ranking on top of that.
      ansi = true
      no_sort = true
      frecency = false
      # The rendered line is "<mark> <repo>@<rest>  <path>".  Strip ANSI and
      # take the second space-separated field — that's the bare session name
      # sesh/tmux need to switch to.
      output = "{strip_ansi|split: :1}"

      [preview]
      command = "tmux list-windows -t {strip_ansi|split: :1} && printf '\\n' && tmux capture-pane -ep -t {strip_ansi|split: :1} | tail -40"

      [ui]
      ui_scale = 90

      [ui.input_bar]
      header = "Tmux Sessions — ⏎ switch · ⌃D kill · ⌃R rename · grouped by repo"

      [ui.preview_panel]
      size = 40

      [keybindings]
      enter = "actions:connect"
      ctrl-d = "actions:kill"
      ctrl-r = "actions:smart-rename"

      [actions.connect]
      description = "Switch to the selected session"
      command = "sesh connect -s {strip_ansi|split: :1}"
      mode = "execute"

      [actions.kill]
      description = "Kill the selected session"
      command = "tmux kill-session -t {strip_ansi|split: :1}"
      mode = "fork"

      [actions.smart-rename]
      description = "Smart-rename all sessions based on cwd + foreground command"
      command = "sesh-tv-rename"
      mode = "fork"
    '';
  };
}
