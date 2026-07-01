# Build Tools

## Scripts

### `build_game.bat` — Windows export
Builds Train45.exe cho Windows. Chạy Godot export preset "Windows Desktop", output tại `../bin/Train45/Train45.exe`.

### `build_android.bat` — Android APK
Build signed release APK. Yêu cầu keystore tại `keystore/train45.keystore`. Output tại `../bin/Android/Train45.apk`.

### `package_import_cache.ps1` — Import cache seed
Đóng gói `.godot/imported/` vào `import_cache.zip` để dùng làm seed cho CI. Chạy sau khi mở project trong Godot editor (để import cache được generate đầy đủ).

```powershell
.\build_tools\package_import_cache.ps1
```

Sau đó upload lên GitHub Release:

```powershell
gh release upload import-cache build_tools\import_cache.zip --clobber
```

## Import Cache & CI

Godot headless không import được font (`.ttf` → `.fontdata`) và audio (`.ogg` → `.oggvorbisstr`) vì thiếu GPU context. CI workflow giải quyết bằng cached import:

1. Lần đầu: tải `import_cache.zip` từ release, giải nén vào `.godot/imported/`
2. Export dùng `--headless` — Godot chỉ việc copy file đã import sẵn vào PCK
3. Lần sau: `actions/cache` khôi phục từ lần trước

Cache key = hash của `**/*.import`. Khi thêm asset mới:
- Chạy `package_import_cache.ps1` local
- Upload lại release: `gh release upload import-cache build_tools\import_cache.zip --clobber`

## CI/CD

- **iOS** (`.github/workflows/build-ios.yml`): Export unsigned Xcode project, xcodebuild không ký. Chạy trên `macos-latest`.
- **macOS** (`.github/workflows/build-macos.yml`): Export unsigned .zip. Chạy trên `macos-latest`.
- Windows/Linux/Android: Build local bằng script, không qua CI.

Kích hoạt bằng `workflow_dispatch` trên GitHub Actions.
