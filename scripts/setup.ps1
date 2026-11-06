# Create or update the shared BrainboxEmb Conda environment on Windows.
# Use conda.exe directly: VS Code's PowerShell "conda" function can print
# shell commands instead of JSON, depending on how the hook was initialized.
[CmdletBinding()]
param(
    [string]$CondaExe
)

$ErrorActionPreference = "Stop"
$environmentFile = Join-Path (Split-Path -Parent $PSScriptRoot) "environment.yml"
$environmentName = "brainboxemb-dev-tools"

# Resolve the actual conda.exe, never the interactive PowerShell 'conda'
# function/alias. Activation is not necessary to create an environment.
$candidates = @()
if ($CondaExe) {
    $candidates += $CondaExe
} else {
    if ($env:CONDA_EXE) { $candidates += $env:CONDA_EXE }
    $condaApp = Get-Command conda.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($condaApp) { $candidates += $condaApp.Source }
    $candidates += @(
        "C:\tools\miniconda3\Scripts\conda.exe"
        "C:\tools\miniforge3\Scripts\conda.exe"
    )
    foreach ($root in @($env:USERPROFILE, $env:LOCALAPPDATA, $env:ProgramData)) {
        if (-not $root) { continue }
        foreach ($distribution in @("miniconda3", "miniforge3", "anaconda3")) {
            $candidates += Join-Path $root "$distribution\Scripts\conda.exe"
        }
    }
}

$condaPath = $candidates |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -First 1
if (-not $condaPath) {
    throw "Cannot find conda.exe. Run with -CondaExe 'C:\path\to\miniconda3\Scripts\conda.exe'."
}
$condaPath = (Resolve-Path -LiteralPath $condaPath).Path
Write-Host "Using: $condaPath"

# Only stdout from the executable is parsed as JSON. Fail with a useful error
# instead of letting ConvertFrom-Json report an opaque 'undefined value'.
$jsonOutput = & $condaPath env list --json
$condaExitCode = $LASTEXITCODE
if ($condaExitCode -ne 0) {
    throw "Conda failed to list environments (exit code $condaExitCode)."
}
$jsonText = ($jsonOutput -join [Environment]::NewLine).Trim()
try {
    if (-not $jsonText) { throw "empty response" }
    $envList = $jsonText | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $envList.envs) { throw "missing 'envs' field" }
} catch {
    throw "Conda did not return valid environment-list JSON. Using: $condaPath. Output: $jsonText"
}
$exists = @($envList.envs | Where-Object {
    (Split-Path $_.TrimEnd('\','/') -Leaf) -eq $environmentName
}).Count -gt 0

if ($exists) {
    Write-Host "Updating existing '$environmentName' environment..."
    & $condaPath env update --name $environmentName --file $environmentFile --prune
} else {
    Write-Host "Creating '$environmentName' environment..."
    & $condaPath env create --file $environmentFile
}
if ($LASTEXITCODE -ne 0) {
    throw "Conda environment creation/update failed."
}

Write-Host "Checking vcs2l..."
& $condaPath run --name $environmentName vcs --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "'vcs' is not available inside '$environmentName'."
}

Write-Host "Environment '$environmentName' is ready."
Write-Host "In VS Code, choose Python: Select Interpreter -> $environmentName."
