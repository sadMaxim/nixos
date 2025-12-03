{ pkgs, ... }:
{
    ###idle
    services.hypridle.enable = true;

    home.packages = with pkgs; [
      wofi
      wev
      hyprpaper
    ];
    
    ##### wofi 
    xdg.configFile."wofi/config".text = ''
      width=600
      height=400
      location=center
      show=drun
      prompt=Search...
      filter_rate=100
      allow_markup=true
      no_actions=true
      halign=fill
      orientation=vertical
      content_halign=fill
      insensitive=true
      allow_images=true
      image_size=40
      gtk_dark=true
    '';

    xdg.configFile."wofi/style.css".text = ''
      window {
        margin: 0px;
        border: 2px solid #33ccff;
        background-color: #1e1e2e;
        border-radius: 10px;
      }

      #input {
        margin: 5px;
        border: none;
        color: #cdd6f4;
        background-color: #313244;
        border-radius: 5px;
        padding: 10px;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #cdd6f4;
      }

      #entry:selected {
        background-color: #313244;
        border-radius: 5px;
      }

      #entry:selected #text {
        color: #33ccff;
      }
    '';

    ### chrome config
    programs.google-chrome = {
      enable = true;
      commandLineArgs = [
        # High DPI scaling (adjust to your needs: 1.25, 1.5, 2.0)
        "--force-device-scale-factor=1.8"

        # Enable proper subpixel rendering
        "--enable-features=UseOzonePlatform,WebContentsForceDark,DefaultEnableFontSubpixelPositioning"

        # Prefer RGB subpixel AA (best on most monitors)
        "--force-color-profile=srgb"

        # Ensure hardware acceleration is on (sharper rendering)
        "--enable-gpu-rasterization"
        "--enable-zero-copy"

        # Text contrast improvements
        "--enable-font-antialiasing"
        "--font-render-hinting=slight"
      ];
    };



    ### wallpaper
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${../beautifulmountainscape.jpg}
      wallpaper = , ${../beautifulmountainscape.jpg}
    '';


    wayland.windowManager.hyprland =
    let
      single = ",preferred,auto,1";
      edp = "eDP-1,preferred,0x0,1";
      dp = "DP-1,preferred,0x-1440,1"; 
      edpno = "eDP-1,disable";
      dpno = "DP-1,disable";
    in
    {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        
        # Monitor configuration
        monitor = [edp  dp];
        
        # i3-style keybindings
        bind = [
          # warpd
          # "$mod, P, exec, warpd --hint2"
          # Lock
          "$mod, BackSpace, exec, hyprlock"

          # Launch apps
          "$mod, Return, exec, kitty"
          "$mod, D, exec, wofi --show drun"
          
          # Window management
          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          
          # Focus (vim-style)
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"
          
          # Move windows
          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
          
          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          
          # Move to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          
          # Fullscreen and floating
          "$mod, F, fullscreen"
          "$mod SHIFT, Space, togglefloating"
          
          # Monitor control
          ", F5, exec, hyprctl --batch 'keyword monitor ${single}; keyword monitor ${edpno}'" 
          ", F6, exec, hyprctl --batch 'keyword monitor ${edp}; keyword monitor ${dpno}'; brightnessctl set 90%" 
          ", F7, exec, hyprctl --batch 'keyword monitor ${edp}; keyword monitor ${dp}'; brightnessctl set 90%" 
          # warpd
        ];
        
        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
        
        # General settings
        general = {
          gaps_in = 2;
          gaps_out = 4;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee)";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
        };
        
        # Decoration
        decoration = {
          rounding = 5;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
        };
        
        # Input
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_shift_toggle";
          follow_mouse = 1;
          repeat_delay = 150;
          repeat_rate = 50;
        };
        
        # Autostart
        exec-once = [
          "hyprpaper"
        ];
      };
    };
}






