{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [ ironbar ];

  xdg.configFile."ironbar/config.json".text = builtins.toJSON {
    icon_theme = "Paper";
    position = "top";
    anchor_to_edges = false;
    height = 32;
    margin = {
      top = 8;
      bottom = 0;
      left = 8;
      right = 8;
    };
    
    start = [
      {
        type = "workspaces";
      }
    ];

    center = [];

    end = [
      {
        type = "sys_info";
        format = [
          "{cpu_percent}% "
          "{memory_percent}% "
        ];
        interval = {
          cpu = 1;
        };
      }
      {
        type = "volume";
      }
      {
        type = "tray";
      }
      {
        type = "clock";
      }
    ];
  };

  xdg.configFile."ironbar/style.css".text = ''
    * {
      font-family: sans-serif;
      font-size: 14px;
      border-radius: 0;
      border: none;
      box-shadow: none;
    }

    popover, popover contents {
      border-radius: 12px;
      padding: 0;
    }

    window {
      background-color: transparent;
    }

    #bar {
      background-color: rgba(30, 30, 46, 0.87);
      border-radius: 8px;
    }

    popover {
      background-color: rgba(30, 30, 46, 0.87);
    }

    popover contents {
      background-color: rgba(30, 30, 46, 0.87);
    }

    box, button, label, calendar {
      background-color: transparent;
    }

    scale.horizontal highlight {
      background-color: #89b4fa;
    }

    scale.vertical highlight {
      background-color: #89b4fa;
    }

    slider {
      border-radius: 100%;
    }

    button {
      padding-left: 0.5em;
      padding-right: 0.5em;
    }

    button:hover, button:active {
      background-color: #313244;
    }

    dropdown popover row:hover, dropdown popover row:focus, dropdown popover row:selected {
      background-color: #313244;
    }

    #start, #end {
      background-color: transparent;
      padding: 4px;
      margin: 4px;
    }

    #start > *, #end > * {
      background-color: rgba(49, 50, 68, 0.6);
      border-radius: 8px;
      padding: 4px 8px;
    }

    #start > * + *, #end > * + * {
      margin-left: 0.5em;
    }

    .popup {
      padding: 1em;
    }

    /* --- clock --- */
    .clock {
      font-weight: bold;
      color: #cdd6f4;
    }

    .popup-clock .calendar-clock {
      font-size: 2.2em;
      margin-bottom: 0.25em;
    }

    .popup-clock .calendar .today {
      background-color: #89b4fa;
      border-radius: 0.25em;
    }

    .popup-clipboard .item {
      padding: 0.25em;
    }

    .popup-clipboard .item + .item {
      border-top: 1px solid #45475a;
    }

    /* --- launcher --- */
    .launcher .item + .item {
      margin-left: 4px;
    }

    .launcher .item.open {
      box-shadow: inset 0 -2px #cdd6f4;
    }

    .launcher .item.focused {
      box-shadow: inset 0 -2px #89b4fa;
    }

    .launcher .item.urgent {
      box-shadow: inset 0 -2px #f38ba8;
    }

    .popup-launcher {
      padding: 0.5em;
    }

    .popup-launcher .popup-item {
      padding: 1em;
      border-radius: 10px;
    }

    .popup-launcher .popup-item label {
      margin-top: 0.5em;
    }

    /* --- menu --- */
    .menu label {
      padding: 0 0.5em;
    }

    .popup-menu .sub-menu {
      border-left: 1px solid #45475a;
      padding-left: 0.5em;
    }

    .popup-menu .category, .popup-menu .application {
      padding: 0.25em;
    }

    .popup-menu .category.open {
      background-color: #313244;
    }

    /* --- music --- */
    .popup-music .album-art {
      margin-right: 1em;
      border-radius: 5px;
    }

    .popup-music .icon-box {
      margin-right: 0.5em;
    }

    .popup-music .title .icon, .popup-music .title .label {
      font-size: 1.5em;
    }

    .popup-music .artist .label, .popup-music .album .label {
      margin-left: 6px;
    }

    .popup-music .volume .icon {
      margin-right: 3px;
    }

    /* --- notifications --- */
    .notifications {
      color: #cdd6f4;
    }

    .notifications .count {
      font-size: 0.8em;
      padding: 0.18em;
    }

    /* --- sysinfo --- */
    .sys-info {
      color: #cdd6f4;
    }

    .sysinfo > .item + .item {
      margin-left: 0.5em;
    }

    /* --- tray --- */
    .tray {
      color: #cdd6f4;
    }

    .tray popover contents {
      padding: 1em;
    }

    /* --- volume --- */
    .volume {
      color: #cdd6f4;
    }

    .popup-volume .device-box {
      border-right: 1px solid #45475a;
    }

    /* --- workspaces --- */
    .workspaces .item {
      color: #45475a;
      padding: 4px 8px;
    }

    .workspaces .item.visible {
      color: #6c7086;
    }

    .workspaces .item.focused {
      color: #cdd6f4;
      box-shadow: inset 0 -2px #89b4fa;
      background-color: transparent;
    }

    .workspaces .item.urgent {
      color: #f38ba8;
      background-color: #f38ba8;
    }

    /* --- custom: power menu ---  */
    .popup-power-menu #header {
      font-size: 1.5em;
      margin-bottom: 0.6em;
    }

    .popup-power-menu .power-btn {
      border: 1px solid #45475a;
      border-radius: 10px;
      padding: 0 1.2em;
    }

    .popup-power-menu .power-btn label {
      font-size: 2.6em;
    }

    .popup-power-menu #buttons > * + * {
      margin-left: 1.3em;
    }
  '';
}
