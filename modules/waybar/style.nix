{ ... }:
let
  custom = {
    font = "Maple Mono";
    font_size = "13px";
    font_weight = "bold";
  };
in
{
  programs.waybar.style = with custom; ''
    * {
      font-family: ${font};
      font-weight: ${font_weight};
      font-size: ${font_size};
    }

    window#waybar {
      background: transparent;
    }
    
    .modules-left,
    .modules-center,
    .modules-right {
      background: #0F0F17;
      border: 2px solid rgba(255, 255, 255, 0.1);
      border-radius: 8px;
      margin: 0px 5px;
      padding: 2px 8px;
    }

    tooltip {
      background: #171717;
      color: #A1BDCE;
      font-size: 13px;
      border-radius: 7px;
      border: 2px solid #101a24;
    }

    #workspaces {
      background: transparent;
      padding: 0px 5px;
    }

    #workspaces button {
      background: transparent;
      color: #6B7280;
      font-size: 14px;
      border: none;
      border-radius: 50%;
      padding: 0px 6px;
      margin: 0px 1px;
      transition: all 0.3s ease;
    }

    #workspaces button.active {
      color: #A1BDCE;
      font-weight: bold;
      transition: all 0.3s ease;
    }

    #workspaces button.urgent {
      color: #FF6B6B;
    }

    #workspaces button:hover {
      background: rgba(114, 215, 146, 0.2);
      color: #72D792;
      transition: all 0.3s ease;
    }

    #custom-spacer {
      opacity: 0.0;
    }

    #custom-smallspacer {
      opacity: 0.0;
    }

    #custom-menu {
      color: #E8EDF0;
      background: rgba(23, 23, 23, 0.0);
      margin: 0px 0px 0px 0px;
      padding-left: 1px;
      padding-right: 1px;
      opacity: 0.1;
    }

    #backlight {
      color: #2096C0;
      background: rgba(23, 23, 23, 0.0);
      font-weight: normal;
      font-size: 19px;
      margin: 1px 0px 0px 0px;
      padding-left: 0px;
      padding-right: 2px;
    }

    #clock {
      color: #A1BDCE;
      font-size: 15px;
      font-weight: 900;
      font-family: ${font};
      background: rgba(23, 23, 23, 0.0);
      opacity: 1;
      margin: 3px 0px 0px 0px;
      padding-left: 10px;
      padding-right: 10px;
      border: none;
    }

    #pulseaudio {
      font-weight: normal;
      font-size: 18px;
      color: #6F8FDB;
      background: rgba(22, 19, 32, 0.0);
      opacity: 1;
      margin: 0px 0px 0px 0px;
      padding-left: 3px;
      padding-right: 3px;
    }

    #cpu {
      color: #915CAF;
      padding: 0px 8px;
    }

    #memory {
      color: #E4C9AF;
      padding: 0px 8px;
    }

    #temperature {
      color: #FF9E64;
      padding: 0px 8px;
    }

    #temperature.critical {
      color: #FF6B6B;
      font-weight: bold;
    }

    #mpris {
      color: white;
      animation: blink 3s linear infinite alternate;
    }

    @keyframes blink {
      to {
        color: #4a4a4a;
      }
    }

    #network {
      color: #A1BDCE;
      font-weight: normal;
      font-size: 19px;
      padding-right: 0px;
      padding-left: 4px;
    }

    #window {
      color: #A1BDCE;
      font-family: ${font};
    }

    #custom-notification {
      font-family: ${font};
      font-size: 17px;
      color: #A1BDCE;
      margin: 2px 0px 0px 0px;
    }

    #pulseaudio-slider slider {
      background: #A1BDCE;
      background-color: transparent;
      box-shadow: none;
      margin-right: 7px;
    }

    #pulseaudio-slider trough {
      margin-top: -3px;
      min-width: 90px;
      min-height: 10px;
      margin-bottom: -4px;
      border-radius: 8px;
      background: #343434;
    }

    #pulseaudio-slider highlight {
      border-radius: 8px;
      background-color: #2096C0;
    }

    #backlight-slider slider {
      background: #A1BDCE;
      background-color: transparent;
      box-shadow: none;
      margin-right: 7px;
    }

    #backlight-slider trough {
      margin-top: -3px;
      min-width: 90px;
      min-height: 10px;
      margin-bottom: -4px;
      border-radius: 8px;
      background: #343434;
    }

    #backlight-slider highlight {
      border-radius: 8px;
      background-color: #2096C0;
    }

    #tray {
      padding: 1px;
    }

    #custom-l_end {
      border-radius: 7px 0px 0px 7px;
      margin-left: 1px;
      padding-left: 3px;
    }

    #custom-r_end {
      border-radius: 0px 7px 7px 0px;
      margin-right: 1px;
      padding-right: 3px;
    }
  '';
}
