# Create or update the shared brainboxemb-dev-tools Conda environment.
# Works in VS Code PowerShell even if "conda init powershell" was not run.
[CmdletBinding()]
param(
    [string]$CondaExe
)

$ErrorActionPreference = "Stop"
$environmentFile = Join-Path (Split-Path -Parent $PSScriptRoot) "environment.yml"

# Selecting a Python interpreter in VS Code does NOT add conda to the shell.
# Prefer the initialized shell command; otherwise locate the actual executable.
if ($CondaExe) {
    if (-not (Test-Path -LiteralPath $CondaExe -PathType Leaf)) {
        throw "Conda executable not found: $CondaExe"
    }
    $condaCommand = (Resolve-Path -LiteralPath $CondaExe).Path
} elseif (Get-Command conda -ErrorAction SilentlyContinue) {
    $condaCommand = "conda"
} else {
    $candidates = @(
        $env:CONDA_EXE
        (Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe")
        (Join-Path $env:USERPROFILE "miniforge3\Scripts\conda.exe")
        (Join-Path $env:LOCALAPPDATA "miniconda3\Scripts\conda.exe")
        (Join-Path $env:LOCALAPPDATA "miniforge3\Scripts\conda.exe")
        (Join-Path $env:ProgramData "miniconda3\Scripts\conda.exe")
        "C:\tools\miniconda3\Scripts\conda.exe"
        "C:\tools\miniforge3\Scripts\conda.exe"
    )
    $condaCommand = $candidates |
        Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
        Select-Object -First 1

    if (-not $condaCommand) {
        throw "Conda could not be found. Use -CondaExe '<your-conda-installation>\Scripts\conda.exe' or initialize PowerShell with 'conda init powershell'."
    }
}

Write-Host "Conda: $condaCommand"

$json = & $condaCommand env list --json
if ($LASTEXITCODE -ne 0) {
    throw "Failed to list Conda environments."
}
$envList = $json | ConvertFrom-Json
$exists = @($envList.envs | Where-Object { (Split-Path $_ -Leaf) -eq "brainboxemb-dev-tools" }).Count -gt 0

if ($exists) {
    Write-Host "Updating existing 'brainboxemb-dev-tools' environment..."
    & $condaCommand env update --name brainboxemb-dev-tools --file $environmentFile --prune
} else {
    Write-Host "Creating 'brainboxemb-dev-tools' environment..."
    & $condaCommand env create --file $environmentFile
}
if ($LASTEXITCODE -ne 0) {
    throw "Conda environment creation/update failed."
}

Write-Host ""
Write-Host "Checking vcs2l..."
& $condaCommand run --name brainboxemb-dev-tools vcs --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "'vcs' is not available inside brainboxemb-dev-tools."
}

Write-Host "Done. Select 'brainboxemb-dev-tools' via Python: Select Interpreter."
Write-Host "To activate in PowerShell, initialize Conda once using 'conda init powershell' and restart VS Code."
