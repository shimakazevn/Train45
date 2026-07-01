$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$importDir = Join-Path $projectDir ".godot\imported"
$outputZip = Join-Path $projectDir "build_tools\import_cache.zip"

if (-not (Test-Path $importDir)) {
    Write-Error "Import cache not found at $importDir"
    Write-Error "Open the project in Godot editor first to generate it."
    exit 1
}

Write-Host "Packaging import cache from $importDir"
Write-Host "Files: $(@(Get-ChildItem -Recurse -File $importDir).Length)"
Write-Host "Size: $((Get-ChildItem -Recurse -File $importDir | Measure-Object Length -Sum).Sum / 1MB) MB"

Compress-Archive -Path "$importDir\*" -DestinationPath $outputZip -CompressionLevel Optimal

Write-Host "Created: $outputZip"
Write-Host "Size: $((Get-Item $outputZip).Length / 1MB) MB"
Write-Host ""
Write-Host "To upload: gh release create import-cache build_tools\import_cache.zip --title 'Import Cache Seed' --notes 'Godot 4.5 import cache for CI builds'"
