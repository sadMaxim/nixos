{ config, pkgs, home-manager, nixvim, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users.maxim = { pkgs, ... }: {
   imports = [ nixvim.homeManagerModules.nixvim ];
   
   nixpkgs.config.allowUnfree = true;
   nixpkgs.config.allowUnfreePredicate = (_:true);
   
   home.packages = with pkgs; [];
   home.stateVersion = "25.05";

    # programs 
    programs = {
      bash.enable = true;

      kitty.enable = true;

      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
      };

      nixvim = (import ./nixvim {inherit pkgs;}) // {
        enable = true;
      };

    };
    
    # Hyprland with i3-style keybindings
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "ALT";
        
        # i3-style keybindings
        bind = [
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
        ];
        
        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
        
        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 10;
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
          kb_layout = "us";
          follow_mouse = 1;
        };
        
        # Autostart
        exec-once = [ "waybar" ];
      };
    };
  };

  services.xserver = {
    enable = true;
    # windowManager.i3 = {
    #    enable = true;
    # };
  };

  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.displayManager.autoLogin.enable = true;
  # services.xserver.displayManager.autoLogin.user = "root";
  # services.xserver.desktopManager.xfce.enable = true;
}
