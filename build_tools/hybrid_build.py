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

DEFAULT_IMPORT_CACHE_URL = ""


def parse_args():
    parser = argparse.ArgumentParser(description="Hybrid build script for macOS and iOS")
    parser.add_argument("platform", choices=["macos", "ios"], help="Target platform")
    parser.add_argument("--project-dir", default=str(Path(__file__).resolve().parent.parent), help="Godot project directory")
    parser.add_argument("--output-dir", default=None, help="Directory for build outputs")
    parser.add_argument("--godot-bin", default=os.environ.get("GODOT_BIN"), help="Path to Godot binary")
    parser.add_argument("--import-cache-url", default=os.environ.get("IMPORT_CACHE_URL", DEFAULT_IMPORT_CACHE_URL), help="Import cache ZIP path or URL")
    parser.add_argument("--skip-import-cache", action="store_true", help="Skip restoring import cache")
    parser.add_argument("--dry-run", action="store_true", help="Print actions without executing")
    return parser.parse_args()


def run(cmd, cwd=None, dry_run=False):
    print("$", " ".join(cmd))
    if dry_run:
        return 0
    completed = subprocess.run(cmd, cwd=cwd, check=False)
    if completed.returncode != 0:
        raise RuntimeError(f"Command failed ({completed.returncode}): {' '.join(cmd)}")
    return completed.returncode


def resolve_godot_bin(explicit_bin: str | None):
    if explicit_bin:
        return explicit_bin
    candidates = []
    env_path = os.environ.get("GODOT_BIN")
    if env_path:
        candidates.append(env_path)
    candidates.extend([
        "godot",
        "godot.exe",
        "godot_console.exe",
        "C:/Users/Shimakaze/AppData/Local/Microsoft/WinGet/Links/godot.exe",
        "C:/Users/Shimakaze/AppData/Local/Microsoft/WinGet/Links/godot_console.exe",
        "C:/Program Files/Godot/Godot.exe",
        "C:/Program Files/Godot/Godot_v4.5-stable_win64_console.exe",
    ])
    for candidate in candidates:
        if not candidate:
            continue
        if os.path.exists(candidate):
            return candidate
        try:
            resolved = shutil.which(candidate)
            if resolved:
                return resolved
        except Exception:
            continue
    return None


def restore_import_cache(project_dir: Path, import_cache_url: str, dry_run: bool):
    if dry_run:
        print("[dry-run] restore import cache")
        return

    godot_dir = project_dir / ".godot"
    tmp_dir = Path(tempfile.mkdtemp(prefix="import_cache_", dir=str(project_dir / "build_tools")))
    try:
        zip_path = tmp_dir / "import_cache.zip"
        local_zip = project_dir / "build_tools" / "import_cache.zip"
        if local_zip.exists():
            print(f"Using local import cache: {local_zip}")
            shutil.copy2(local_zip, zip_path)
        elif import_cache_url:
            print(f"Downloading import cache from {import_cache_url}")
            urllib.request.urlretrieve(import_cache_url, zip_path)
        else:
            raise RuntimeError("No local import cache found and no online URL provided")

        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(tmp_dir / "extracted")

        extracted_dir = tmp_dir / "extracted"
        if (extracted_dir / "imported").exists():
            target_imported = godot_dir / "imported"
            target_imported.mkdir(parents=True, exist_ok=True)
            for item in (extracted_dir / "imported").iterdir():
                dest = target_imported / item.name
                if item.is_dir():
                    shutil.copytree(item, dest, dirs_exist_ok=True)
                else:
                    shutil.copy2(item, dest)
        for filename in ["uid_cache.bin", "global_script_class_cache.cfg", ".gdignore"]:
            src = extracted_dir / filename
            if src.exists():
                shutil.copy2(src, godot_dir / filename)

        if not (godot_dir / "imported").exists() or not any((godot_dir / "imported").iterdir()):
            raise RuntimeError("Import cache restore failed: no imported files found")

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def build_macos(project_dir: Path, output_dir: Path, godot_bin: str | None, dry_run: bool):
    output_dir.mkdir(parents=True, exist_ok=True)
    output_zip = output_dir / "Train45-macOS.zip"
    if dry_run:
        print(f"[dry-run] would export macOS to {output_zip}")
        return output_zip

    if not godot_bin:
        raise RuntimeError("GODOT_BIN is required for macOS build")

    cmd = [godot_bin, "--headless", "--path", str(project_dir), "--export-release", "macOS", str(output_zip)]
    run(cmd, cwd=project_dir, dry_run=dry_run)
    return output_zip


def build_ios(project_dir: Path, output_dir: Path, godot_bin: str | None, dry_run: bool):
    output_dir.mkdir(parents=True, exist_ok=True)
    export_zip = output_dir / "Train45.zip"
    xcodeproj = output_dir / "Train45.xcodeproj"
    ipa_path = output_dir / "Train45-iOS.ipa"

    if dry_run:
        print(f"[dry-run] would export iOS to {export_zip} and package IPA to {ipa_path}")
        return ipa_path

    if not godot_bin:
        raise RuntimeError("GODOT_BIN is required for iOS build")

    run([godot_bin, "--headless", "--path", str(project_dir), "--export-release", "iOS", str(export_zip)], cwd=project_dir, dry_run=dry_run)
    if not xcodeproj.exists():
        raise RuntimeError(f"Expected Xcode project at {xcodeproj} after Godot export")

    build_cmd = [
        "xcodebuild",
        "-project",
        str(xcodeproj),
        "-scheme",
        "Train45",
        "-configuration",
        "Release",
        "CODE_SIGNING_ALLOWED=NO",
        "CODE_SIGNING_REQUIRED=NO",
        "CODE_SIGN_IDENTITY=",
        "CODE_SIGN_STYLE=Manual",
        "DEVELOPMENT_TEAM=",
        "PROVISIONING_PROFILE_SPECIFIER=",
        "build",
    ]
    run(build_cmd, cwd=project_dir, dry_run=dry_run)

    app_path = None
    for candidate in [Path("~/Library/Developer/Xcode/DerivedData"), project_dir / output_dir.name]:
        resolved = candidate.expanduser()
        if resolved.exists():
            matches = list(resolved.rglob("Train45.app"))
            if matches:
                app_path = matches[0]
                break
    if app_path is None:
        raise RuntimeError("Could not find built Train45.app for iOS packaging")

    payload_dir = output_dir / "Payload"
    payload_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(app_path, payload_dir / app_path.name, dirs_exist_ok=True)
    shutil.make_archive(str(output_dir / "Train45-iOS"), "zip", root_dir=output_dir, base_dir="Payload")
    shutil.move(str(output_dir / "Train45-iOS.zip"), ipa_path)
    return ipa_path


def main():
    args = parse_args()
    project_dir = Path(args.project_dir).resolve()
    output_dir = Path(args.output_dir).resolve() if args.output_dir else project_dir / "dist"
    godot_bin = resolve_godot_bin(args.godot_bin)
    if not args.skip_import_cache:
        restore_import_cache(project_dir, args.import_cache_url, args.dry_run)

    if args.platform == "macos":
        artifact = build_macos(project_dir, output_dir, godot_bin, args.dry_run)
    else:
        artifact = build_ios(project_dir, output_dir, godot_bin, args.dry_run)

    print(f"Artifact: {artifact}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # pragma: no cover - CLI error handling
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
