$projectDir = Split-Path -Parent $PSScriptRoot
$godotDir = Join-Path $projectDir ".godot"
$outputZip = Join-Path $projectDir "build_tools\import_cache.zip"
$tempDir = Join-Path $projectDir "build_tools\.temp_cache"

if (-not (Test-Path $godotDir)) {
    Write-Error ".godot directory not found at $godotDir"
    Write-Error "Open the project in Godot editor first to generate it."
    exit 1
}

# Clean and recreate temp directory
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy essential cache files (exclude editor/ folding caches - not needed for export)
Copy-Item -Recurse (Join-Path $godotDir "imported") -Destination $tempDir
Copy-Item (Join-Path $godotDir "uid_cache.bin") -Destination $tempDir
Copy-Item (Join-Path $godotDir "global_script_class_cache.cfg") -Destination $tempDir
Copy-Item (Join-Path $godotDir ".gdignore") -Destination $tempDir

Write-Host "Packaging import cache from .godot/ (imported/ + uid_cache.bin + global_script_class_cache.cfg)"
$files = Get-ChildItem -Recurse -File $tempDir
$totalSize = ($files | Measure-Object Length -Sum).Sum
Write-Host "Files: $($files.Length)"
Write-Host "Size: $($totalSize / 1MB) MB"

# Remove old zip if exists
if (Test-Path $outputZip) { Remove-Item -Force $outputZip }

Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -CompressionLevel Optimal

# Cleanup temp
Remove-Item -Recurse -Force $tempDir

Write-Host "Created: $outputZip"
Write-Host "Size: $((Get-Item $outputZip).Length / 1MB) MB"
Write-Host ""
Write-Host "To upload: gh release upload import-cache build_tools\import_cache.zip --clobber"
