#!/usr/bin/env bash
# Toggle eDP-1 (laptop screen) on/off

if hyprctl monitors | grep -q "eDP-1"; then
    # eDP-1 is active, disable it
    hyprctl keyword monitor "eDP-1,disable"
else
    # eDP-1 is disabled, enable it
    hyprctl keyword monitor "eDP-1,preferred,auto,1"
fi
