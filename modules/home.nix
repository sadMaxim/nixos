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
    seshTv = pkgs.writeShellApplication {
      name = "sesh-tv";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.gnused
        pkgs.sesh
        pkgs.television
        pkgs.tmux
      ];
      text = ''
        set -euo pipefail

        while true; do
          selection="$(${pkgs.television}/bin/tv \
            --source-command 'sesh list -t | LC_ALL=C sort' \
            --preview-command 'tmux list-windows -t {} && printf "\\n" && tmux capture-pane -ep -t {} | tail -40' \
            --preview-size 60 \
            --expect 'ctrl-d;ctrl-r')" || exit 0

          first_line="$(printf '%s\n' "$selection" | sed -n '1p')"

          if [ "$first_line" = "ctrl-d" ]; then
            session="$(printf '%s\n' "$selection" | sed -n '2p')"
            [ -n "$session" ] || continue
            tmux kill-session -t "$session"
            continue
          fi

          smart_name() {
            dir="$1"
            cmd="$2"

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
              base="$repo@$branch"
            else
              base="$(basename "$dir")"
            fi

            case "$cmd" in
              bash|zsh|fish|sh|tmux|nu) printf '%s\n' "$(clean_name "$base")" ;;
              *) printf '%s\n' "$(clean_name "$base-$cmd")" ;;
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

          if [ "$first_line" = "ctrl-r" ]; then
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
            continue
          fi

          # With --expect, tv may output the confirm key on the first line
          # before the selected session. Fall back to the full output if not.
          session="$(printf '%s\n' "$selection" | sed -n '2p')"
          [ -n "$session" ] || session="$selection"
          [ -n "$session" ] || exit 0
          exec sesh connect -s "$session"
        done
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
     # Tmux/sesh popup helper with preview, Ctrl-d kill, and Ctrl-r smart rename
     seshTv
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
     # Desktop Telegram client
     telegram-desktop
        # Age encryption tool
        age
      # Image manipulation tool
      imagemagick

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
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      vscode = {
        enable = true;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          saoudrizwan.claude-dev
        ];
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
    

  };
}
