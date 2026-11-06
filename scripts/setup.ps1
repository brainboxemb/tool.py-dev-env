<#
.SYNOPSIS
    Install or update the shared BrainboxEmb Python tools environment.

.DESCRIPTION
    Creates or updates the Conda environment 'brainboxemb-dev-tools' using
    environment.yml from this repository. 'conda env update' handles both
    cases, so listing existing environments or parsing JSON is unnecessary.

    Calls conda.exe directly: VS Code's PowerShell 'conda' shell hook may
    not be initialized. Does not change PATH, PowerShell profiles or the
    Python interpreter selected in VS Code.

.PARAMETER CondaExe
    Optional path to the actual conda.exe. By default the script searches
    PATH, CONDA_EXE and common Windows installation locations.

.EXAMPLE
    .\scripts\setup.ps1

.EXAMPLE
    .\scripts\setup.ps1 -CondaExe 'C:\tools\miniconda3\Scripts\conda.exe'
#>
[CmdletBinding()]
param(
    [string]$CondaExe
)

$ErrorActionPreference = "Stop"

if ($CondaExe -and -not (Test-Path -LiteralPath $CondaExe -PathType Leaf)) {
    throw "Specified Conda executable not found: $CondaExe"
}

# 1. Find the executable, not the PowerShell 'conda' function/alias.
$onPath = Get-Command conda.exe -CommandType Application -ErrorAction SilentlyContinue
$candidates = @(
    $CondaExe
    $env:CONDA_EXE
    $(if ($onPath) { $onPath.Source })
    'C:\tools\miniconda3\Scripts\conda.exe'
    'C:\tools\miniforge3\Scripts\conda.exe'
    $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'miniconda3\Scripts\conda.exe' })
    $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'miniforge3\Scripts\conda.exe' })
    $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'miniconda3\Scripts\conda.exe' })
)
$conda = $candidates |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -First 1
if (-not $conda) {
    throw "Conda executable not found. Supply -CondaExe 'C:\path\to\Scripts\conda.exe'."
}
$conda = (Resolve-Path -LiteralPath $conda).Path

# 2. Apply environment.yml. Conda creates the environment if absent and
#    updates it otherwise; --prune removes obsolete Conda dependencies.
$definition = Join-Path (Split-Path -Parent $PSScriptRoot) 'environment.yml'
$name = 'brainboxemb-dev-tools'
Write-Host "Conda: $conda"
Write-Host "Creating/updating: $name"
& $conda env update --name $name --file $definition --prune
if ($LASTEXITCODE -ne 0) {
    throw "Conda failed to create/update '$name' (exit code $LASTEXITCODE)."
}

# 3. Verify the CLI tool is available, without activating the environment.
& $conda run --name $name vcs --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "vcs2l validation failed in '$name' (exit code $LASTEXITCODE)."
}
Write-Host "Ready: $name. In VS Code choose Python: Select Interpreter."
