#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Hybrid build script for macOS and iOS")
    parser.add_argument("platform", choices=["macos", "ios", "both"], help="Target platform")
    parser.add_argument("--project-dir", default=str(Path(__file__).resolve().parent.parent), help="Godot project directory")
    parser.add_argument("--output-dir", default=None, help="Directory for build outputs")
    parser.add_argument("--godot-bin", default=os.environ.get("GODOT_BIN"), help="Path to Godot binary")
    return parser.parse_args()


def run(cmd, cwd=None):
    print("$", " ".join(cmd))
    result = subprocess.run(cmd, cwd=cwd, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(cmd)}")
    return result.returncode


def resolve_godot_bin(explicit_bin: str | None):
    if explicit_bin:
        return explicit_bin
    for candidate in ["godot", "godot.exe", "godot_console.exe"]:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    return None


def build_macos(project_dir: Path, output_dir: Path, godot_bin: str | None):
    output_dir.mkdir(parents=True, exist_ok=True)
    output_zip = output_dir / "Train45-macOS.zip"
    if not godot_bin:
        raise RuntimeError("GODOT_BIN is required for macOS build")
    run([godot_bin, "--headless", "--path", str(project_dir), "--export-release", "macOS", str(output_zip)], cwd=project_dir)
    return output_zip


def build_ios(project_dir: Path, output_dir: Path, godot_bin: str | None):
    output_dir.mkdir(parents=True, exist_ok=True)
    export_zip = output_dir / "Train45.zip"
    if not godot_bin:
        raise RuntimeError("GODOT_BIN is required for iOS build")
    run([godot_bin, "--headless", "--path", str(project_dir), "--export-release", "iOS", str(export_zip)], cwd=project_dir)
    return export_zip


def main():
    args = parse_args()
    project_dir = Path(args.project_dir).resolve()
    output_dir = Path(args.output_dir).resolve() if args.output_dir else project_dir / "dist"
    godot_bin = resolve_godot_bin(args.godot_bin)
    if args.platform in ["macos", "both"]:
        artifact = build_macos(project_dir, output_dir, godot_bin)
        print(f"macOS artifact: {artifact}")
    if args.platform in ["ios", "both"]:
        artifact = build_ios(project_dir, output_dir, godot_bin)
        print(f"iOS artifact: {artifact}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
