#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


CACHE_DIR = Path("/tmp")


def run(cmd):
    return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def resolve_serial():
    env_serial = os.getenv("DDCUTIL_SERIAL")
    if env_serial:
        return env_serial

    try:
        res = run(["hyprctl", "monitors", "-j"])
        monitors = json.loads(res.stdout)
        focused = next((m for m in monitors if m.get("focused")), None)
        candidates = [focused] if focused else []
        candidates += monitors
        for mon in candidates:
            if mon and mon.get("serial"):
                return mon["serial"]
    except Exception:
        pass

    try:
        res = run(["ddcutil", "detect", "--terse"])
        for line in res.stdout.splitlines():
            if "Serial number:" in line:
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return None


def cache_path(serial: str) -> Path:
    safe_serial = serial.replace("/", "_")
    return CACHE_DIR / f"ddcutil-brightness-cache-{safe_serial}.txt"


def read_cache(serial: str):
    try:
        return int(cache_path(serial).read_text().strip())
    except Exception:
        return None


def write_cache(serial: str, value: int):
    try:
        cache_path(serial).write_text(str(value))
    except Exception:
        pass


def get_brightness(serial: str):
    cmd = [
        "ddcutil",
        "getvcp",
        "10",
        "--sn",
        serial,
        "--maxtries",
        ".,15,.",
    ]
    res = run(cmd)
    if res.returncode == 0 and "current value" in res.stdout:
        try:
            current = int(
                res.stdout.split("current value =")[1].split(",")[0].strip()
            )
            write_cache(serial, current)
            return current
        except Exception:
            pass
    cached = read_cache(serial)
    if cached is not None:
        return cached
    return None


def set_brightness(serial: str, value: int):
    clamped = max(0, min(100, value))
    cmd = [
        "ddcutil",
        "setvcp",
        "10",
        str(clamped),
        "--sn",
        serial,
        "--maxtries",
        "15,.,.",
    ]
    run(cmd)
    write_cache(serial, clamped)
    return clamped


def output_json(percentage: int | None, tooltip: str | None = None):
    payload = {}
    if percentage is not None:
        payload["percentage"] = percentage
    if tooltip:
        payload["tooltip"] = tooltip
    print(json.dumps(payload))


def main():
    parser = argparse.ArgumentParser(description="Control external monitor brightness via ddcutil.")
    parser.add_argument("--get", action="store_true", help="Get current brightness")
    parser.add_argument("--inc", type=int, help="Increase brightness by amount")
    parser.add_argument("--dec", type=int, help="Decrease brightness by amount")
    parser.add_argument("--set", dest="set_value", type=int, help="Set brightness to value 0-100")
    parser.add_argument("--serial", help="Override monitor serial")
    args = parser.parse_args()

    serial = args.serial or resolve_serial()
    if not serial:
        output_json(None, "No DDC/CI monitor detected")
        return

    current = get_brightness(serial)
    if args.set_value is not None:
        new_value = set_brightness(serial, args.set_value)
        output_json(new_value)
        return

    if args.inc is not None:
        base = current if current is not None else 0
        new_value = set_brightness(serial, base + args.inc)
        output_json(new_value)
        return

    if args.dec is not None:
        base = current if current is not None else 0
        new_value = set_brightness(serial, base - args.dec)
        output_json(new_value)
        return

    output_json(current)


if __name__ == "__main__":
    main()
