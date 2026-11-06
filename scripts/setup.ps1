# Create or update the shared brainboxemb-dev-tools Conda environment from any directory.
# No global Conda settings or PowerShell profiles are changed.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$environmentFile = Join-Path (Split-Path -Parent $PSScriptRoot) "environment.yml"

if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
    throw "Conda is not available on PATH. Install Miniforge (or another Conda distribution) and open a new terminal."
}

$envList = conda env list --json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    throw "Failed to list Conda environments."
}

$exists = @($envList.envs | Where-Object { (Split-Path $_ -Leaf) -eq "brainboxemb-dev-tools" }).Count -gt 0

if ($exists) {
    Write-Host "Updating existing 'brainboxemb-dev-tools' environment..."
    conda env update --name brainboxemb-dev-tools --file $environmentFile --prune
} else {
    Write-Host "Creating 'brainboxemb-dev-tools' environment..."
    conda env create --file $environmentFile
}

if ($LASTEXITCODE -ne 0) {
    throw "Conda environment creation/update failed."
}

Write-Host ""
Write-Host "Checking vcs2l..."
conda run --name brainboxemb-dev-tools vcs --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "'vcs' is not available inside brainboxemb-dev-tools."
}

Write-Host "Done. Activate in your VS Code terminal: conda activate brainboxemb-dev-tools"
