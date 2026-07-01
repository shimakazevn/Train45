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

DEFAULT_IMPORT_CACHE_URL = "https://github.com/shimakazevn/Train45/releases/download/import-cache/import_cache.zip"


def parse_args():
    parser = argparse.ArgumentParser(description="Hybrid build script for macOS and iOS")
    parser.add_argument("platform", choices=["macos", "ios", "both"], help="Target platform")
    parser.add_argument("--project-dir", default=str(Path(__file__).resolve().parent.parent), help="Godot project directory")
    parser.add_argument("--output-dir", default=None, help="Directory for build outputs")
    parser.add_argument("--godot-bin", default=os.environ.get("GODOT_BIN"), help="Path to Godot binary")
    parser.add_argument("--import-cache-url", default=os.environ.get("IMPORT_CACHE_URL", DEFAULT_IMPORT_CACHE_URL), help="Import cache ZIP URL")
    parser.add_argument("--skip-import-cache", action="store_true", help="Skip restoring the import cache")
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


def restore_import_cache(project_dir: Path, import_cache_url: str | None):
    if not import_cache_url:
        return

    godot_dir = project_dir / ".godot"
    godot_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir = Path(tempfile.mkdtemp(prefix="import_cache_", dir=str(project_dir)))
    try:
        zip_path = tmp_dir / "import_cache.zip"
        local_zip = project_dir / "build_tools" / "import_cache.zip"
        if local_zip.exists():
            shutil.copy2(local_zip, zip_path)
        else:
            print(f"Downloading import cache from {import_cache_url}")
            urllib.request.urlretrieve(import_cache_url, zip_path)

        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(tmp_dir / "extracted")

        extracted_dir = tmp_dir / "extracted"
        imported_roots = [extracted_dir / "imported", extracted_dir / ".godot" / "imported"]
        for imported_root in imported_roots:
            if imported_root.exists():
                target_imported = godot_dir / "imported"
                target_imported.mkdir(parents=True, exist_ok=True)
                for item in imported_root.iterdir():
                    dest = target_imported / item.name
                    if item.is_dir():
                        shutil.copytree(item, dest, dirs_exist_ok=True)
                    else:
                        shutil.copy2(item, dest)

        for filename in ["uid_cache.bin", "global_script_class_cache.cfg", ".gdignore"]:
            for src in [extracted_dir / filename, extracted_dir / ".godot" / filename]:
                if src.exists():
                    shutil.copy2(src, godot_dir / filename)
                    break

        if not (godot_dir / "imported").exists() or not any((godot_dir / "imported").iterdir()):
            raise RuntimeError("Import cache restore failed: no imported files found")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


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
    ipa_path = output_dir / "Train45-iOS.ipa"
    if not godot_bin:
        raise RuntimeError("GODOT_BIN is required for iOS build")

    run([godot_bin, "--headless", "--path", str(project_dir), "--export-release", "iOS", str(export_zip)], cwd=project_dir)

    xcodeproj_candidates = sorted(project_dir.rglob("Train45.xcodeproj"))
    if not xcodeproj_candidates:
        raise RuntimeError("No Train45.xcodeproj was produced by the iOS export")
    xcodeproj = xcodeproj_candidates[0]

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
    run(build_cmd, cwd=project_dir)

    app_path = None
    for base in [Path("~/Library/Developer/Xcode/DerivedData").expanduser(), output_dir]:
        if base.exists():
            matches = list(base.rglob("Train45.app"))
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
        restore_import_cache(project_dir, args.import_cache_url)

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
