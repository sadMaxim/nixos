{ ... }:
let
  custom = {
    font = "Maple Mono";
    font_size = "15px";
    font_weight = "bold";
  };
in
{
  programs.waybar.settings.mainBar = with custom; {
    layer = "bottom";
    position = "bottom";
    margin-left = 10;
    margin-right = 10;
    margin-top = 0;
    margin-bottom = 1;
    exclusive = true;
    passthrough = false;
    gtk-layer-shell = true;
    reload_style_on_change = true;
    
    modules-left = [
      "custom/smallspacer"
      "hyprland/workspaces"
      "custom/spacer"
      "mpris"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "custom/padd"
      "custom/l_end"
      "group/expand"
      "network"
      "group/expand-3"
      "group/expand-2"
      "memory"
      "cpu"
      "custom/temperature"
      "clock"
      "custom/notification"
      "custom/padd"
    ];
    "custom/smallspacer" = {
      format = " ";
    };
    "custom/spacer" = {
      format = "|";
    };
    "custom/padd" = {
      format = "  ";
      interval = "once";
      tooltip = false;
    };
    "custom/l_end" = {
      format = " ";
      interval = "once";
      tooltip = false;
    };
    "custom/r_end" = {
      format = " ";
      interval = "once";
      tooltip = false;
    };
    "group/expand" = {
      orientation = "horizontal";
      drawer = {
        transition-duration = 600;
        children-class = "not-power";
        transition-to-left = true;
      };
      modules = [
        "custom/menu"
        "custom/spacer"
        "tray"
      ];
    };
    "custom/menu" = {
      format = "󰅃";
      rotate = 90;
    };
    tray = {
      icon-size = 16;
      rotate = 0;
      spacing = 3;
    };
    "hyprland/workspaces" = {
      format = "{icon}";
      all-outputs = true;
      active-only = false;
      format-icons = {
        default = "○";
        active = "●";
        urgent = "";
      };
      persistent-workspaces = {
        "1" = [];
        "2" = [];
        "3" = [];
        "4" = [];
        "5" = [];
      };
    };
    mpris = {
      format = "{player_icon} {dynamic}";
      format-paused = "<span color='grey'>{status_icon} {dynamic}</span>";
      max-length = 50;
      player-icons = {
        default = "⏸";
        mpv = "🎵";
      };
      status-icons = {
        paused = "▶";
      };
    };
    "hyprland/window" = {
      format = "{class}: {title}";
      max-length = 60;
      separate-outputs = true;
    };
    cpu = {
      interval = 2;
      format = " {usage}%";
      tooltip = true;
      tooltip-format = "CPU: {usage}%\nAvg Frequency: {avg_frequency}GHz";
    };
    memory = {
      interval = 2;
      format = " {percentage}%";
      tooltip = true;
      tooltip-format = "RAM: {used:0.1f}G / {total:0.1f}G ({percentage}%)";
    };
    "custom/temperature" = {
      exec = "sensors -A | grep 'Core' | awk '{sum+=$3; count++} END {printf \"%.0f°C\", sum/count}'";
      interval = 2;
      format = " {}";
      tooltip = true;
      exec-tooltip = "sensors -A | grep 'Core'";
    };
    clock = {
      format = "{:%I:%M %p}";
      rotate = 0;
      tooltip-format = "<tt>{calendar}</tt>";
      calendar = {
        mode = "month";
        mode-mon-col = 3;
        on-scroll = 1;
        on-click-right = "mode";
        format = {
          months = "<span color='#ffead3'><b>{}</b></span>";
          weekdays = "<span color='#ffcc66'><b>{}</b></span>";
          today = "<span color='#ff6699'><b>{}</b></span>";
        };
      };
    };
    network = {
      tooltip = true;
      format-wifi = "{icon} ";
      format-icons = [ "󰤟" "󰤢" "󰤥" ];
      rotate = 0;
      format-ethernet = "󰈀 ";
      tooltip-format = "Network: <big><b>{essid}</b></big>\nSignal strength: <b>{signaldBm}dBm ({signalStrength}%)</b>\nFrequency: <b>{frequency}MHz</b>\nInterface: <b>{ifname}</b>\nIP: <b>{ipaddr}/{cidr}</b>\nGateway: <b>{gwaddr}</b>\nNetmask: <b>{netmask}</b>";
      format-linked = "󰈀 {ifname} (No IP)";
      format-disconnected = " ";
      tooltip-format-disconnected = "Disconnected";
      interval = 2;
      on-click = "kitty --class floating -e nmtui";
    };
    "group/expand-2" = {
      orientation = "horizontal";
      drawer = {
        transition-duration = 600;
        children-class = "not-power";
        transition-to-left = true;
        click-to-reveal = true;
      };
      modules = [
        "backlight"
        "backlight/slider"
      ];
    };
    backlight = {
      device = "intel_backlight";
      rotate = 0;
      format = "{icon}";
      format-icons = [ "󰃞" "󰃝" "󰃟" "󰃠" ];
      scroll-step = 1;
      min-length = 2;
    };
    "backlight/slider" = {
      min = 5;
      max = 100;
      rotate = 0;
      device = "intel_backlight";
      scroll-step = 1;
    };
    "group/expand-3" = {
      orientation = "horizontal";
      drawer = {
        transition-duration = 600;
        children-class = "not-power";
        transition-to-left = true;
        click-to-reveal = true;
      };
      modules = [
        "pulseaudio"
        "pulseaudio/slider"
      ];
    };
    pulseaudio = {
      format = "{icon}";
      rotate = 0;
      format-muted = "婢";
      tooltip-format = "{icon} {desc} // {volume}%";
      scroll-step = 5;
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [ "" "" "" ];
      };
    };
    "pulseaudio/slider" = {
      min = 5;
      max = 100;
      rotate = 0;
      scroll-step = 1;
    };
    "custom/notification" = {
      tooltip = false;
      format = "{icon}";
      format-icons = {
        notification = "󰅸";
        none = "󰂜";
        dnd-notification = "󰅸";
        dnd-none = "󱏨";
        inhibited-notification = "󰅸";
        inhibited-none = "󰂜";
        dnd-inhibited-notification = "󰅸";
        dnd-inhibited-none = "󱏨";
      };
      return-type = "json";
      exec-if = "which swaync-client";
      exec = "swaync-client -swb";
      on-click-right = "swaync-client -d -sw";
      on-click = "swaync-client -t -sw";
      escape = true;
    };
  };
}
