# PowerShell script to convert xcarchive to ipa
# Usage: .\create_ipa.ps1 -XcarchivePath "path\to\your.xcarchive" -OutputIpa "output.ipa"

param(
    [Parameter(Mandatory=$true)]
    [string]$XcarchivePath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputIpa
)

# Check if xcarchive exists
if (-not (Test-Path $XcarchivePath)) {
    Write-Error "xcarchive not found at: $XcarchivePath"
    exit 1
}

# Create Payload directory
$payloadDir = "Payload"
if (Test-Path $payloadDir) {
    Remove-Item -Recurse -Force $payloadDir
}
New-Item -ItemType Directory -Path $payloadDir | Out-Null

# Copy the Runner.app bundle
$appPath = Join-Path $XcarchivePath "Products\Applications\Runner.app"
if (-not (Test-Path $appPath)) {
    Write-Error "Runner.app not found in xcarchive at: $appPath"
    exit 1
}

Copy-Item -Recurse -Path $appPath -Destination $payloadDir

# Create the ipa (which is just a zip file)
Write-Host "Creating IPA file..."
Compress-Archive -Path $payloadDir -DestinationPath $OutputIpa -Force

# Clean up
Remove-Item -Recurse -Force $payloadDir

Write-Host "Successfully created: $OutputIpa"
