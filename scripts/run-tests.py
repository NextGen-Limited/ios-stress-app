#!/usr/bin/env python3
"""Run StressMonitor unit tests via xcodebuild. Works locally and in CI."""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent / "StressMonitor"
PROJECT = PROJECT_DIR / "StressMonitor.xcodeproj"
SCHEME = "StressMonitor"
TEST_TARGET = "StressMonitorTests"
BUILD_DIR = PROJECT_DIR / "build"


def get_simulators() -> dict:
    """Get all available simulators from simctl."""
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Failed to list simulators: {result.stderr}")
        sys.exit(1)
    return json.loads(result.stdout)


def find_booted_iphone(data: dict) -> tuple[str, str] | None:
    """Find an already-booted iPhone simulator. Returns (udid, name) or None."""
    for runtime, devices in data["devices"].items():
        if "iOS" not in runtime:
            continue
        for d in devices:
            if d["name"].startswith("iPhone") and d["state"] == "Booted":
                return (d["udid"], d["name"])
    return None


def find_available_iphone(data: dict) -> tuple[str, str] | None:
    """Find the best available iPhone simulator. Returns (udid, name) or None."""
    # Prefer these models in order
    preferred = [
        "iPhone 16", "iPhone 16 Pro", "iPhone 16 Pro Max",
        "iPhone 17", "iPhone 17 Pro", "iPhone 17 Pro Max",
        "iPhone 15", "iPhone 15 Pro",
        "iPhone 16e", "iPhone 17e", "iPhone 15e",
        "iPhone Air",
    ]
    for name in preferred:
        for runtime, devices in data["devices"].items():
            if "iOS" not in runtime:
                continue
            for d in devices:
                if d["name"] == name and d["isAvailable"]:
                    return (d["udid"], d["name"])

    # Fallback: any available iPhone
    for runtime, devices in data["devices"].items():
        if "iOS" not in runtime:
            continue
        for d in devices:
            if d["name"].startswith("iPhone") and d["isAvailable"]:
                return (d["udid"], d["name"])
    return None


def boot_simulator(udid: str, name: str) -> None:
    """Boot simulator if not already booted."""
    print(f"Booting {name} ({udid[:8]}...)")
    subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True)
    try:
        subprocess.run(
            ["xcrun", "simctl", "bootstatus", udid, "-b"],
            capture_output=True, timeout=60,
        )
    except subprocess.TimeoutExpired:
        print("WARN: bootstatus timed out, continuing...")


def run_tests(ci: bool = False) -> int:
    """Build and run tests. Returns xcodebuild exit code."""
    data = get_simulators()

    # Prefer already-booted simulator
    booted = find_booted_iphone(data)
    if booted:
        udid, name = booted
        print(f"Using already-booted simulator: {name}")
    else:
        found = find_available_iphone(data)
        if not found:
            print("ERROR: No available iPhone simulator found")
            sys.exit(1)
        udid, name = found
        boot_simulator(udid, name)

    # Clean previous build artifacts
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    cmd = [
        "xcodebuild", "test",
        "-project", str(PROJECT),
        "-scheme", SCHEME,
        "-destination", f"platform=iOS Simulator,id={udid}",
        "-destination-timeout", "120",
        f"-only-testing:{TEST_TARGET}",
        "-resultBundlePath", str(BUILD_DIR / "TestResults.xcresult"),
    ]

    if ci:
        cmd.extend(["CODE_SIGNING_ALLOWED=NO", "CI=1"])

    print(f"\nRunning: {' '.join(cmd)}\n")
    result = subprocess.run(cmd, cwd=str(PROJECT_DIR))
    return result.returncode


def main():
    ci = os.environ.get("CI", "").lower() in ("1", "true")
    print(f"Mode: {'CI' if ci else 'Local'}")
    print(f"Project: {PROJECT}")
    print(f"Scheme: {SCHEME}")
    print(f"Test target: {TEST_TARGET}\n")

    exit_code = run_tests(ci=ci)

    if exit_code == 0:
        print("\nAll tests passed")
    else:
        print(f"\nTests failed (exit code {exit_code})")

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
