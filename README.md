# tool.py-dev-env

Version-controlled Conda environment for shared Python development utilities.
The environment is named **`brainboxemb-dev-tools`** and can be reused across
repositories. The first tool is [vcs2l](https://github.com/ros-infrastructure/vcs2l)
for checking out pinned dependencies from `dependencies.repos`.

Project-specific Python dependencies belong in separate environments.

## Install (Windows)

Requires Miniconda, Miniforge or another Conda distribution. Miniconda can
optionally be installed or upgraded through Chocolatey (administrator terminal):

```powershell
choco install miniconda3 -y
# Or, if already installed:
choco upgrade miniconda3 -y
```

Before upgrading an existing installation, make sure any Conda environments
you need to keep are backed up.

From the root of this repository in PowerShell:

```powershell
.\scripts\setup.ps1
```

The script reads [`environment.yml`](environment.yml), creates or updates
`brainboxemb-dev-tools`, and checks whether `vcs` is installed. It uses
`conda.exe` directly, so activating Conda first is not necessary. The script
does not change PATH, PowerShell profiles or VS Code settings.

For a non-standard installation path:

```powershell
.\scripts\setup.ps1 -CondaExe "<conda-install-dir>\Scripts\conda.exe"
```

The script has built-in PowerShell documentation:

```powershell
Get-Help .\scripts\setup.ps1 -Full
```

## Use in VS Code

After installation, press **Ctrl+Shift+P**, choose **Python: Select
Interpreter**, and select **`brainboxemb-dev-tools`**. Open a new integrated
terminal to use the selected interpreter.

You can also explicitly activate the environment in an initialized PowerShell
terminal:

```powershell
conda activate brainboxemb-dev-tools
vcs --help
```

If PowerShell has not been initialized for Conda, run the Conda hook from your
Miniconda installation first, or initialize PowerShell once with
`conda init powershell` and reopen VS Code. Selecting an interpreter and
activating a terminal are separate operations.

## Example: OpenSCAD model archive

Inside a clone of
[`2026-011-01.cad.model-archive`](https://github.com/brainboxemb/2026-011-01.cad.model-archive),
with `brainboxemb-dev-tools` activated:

```powershell
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
.\scripts\open-model.ps1
```

This fetches the pinned NopSCADlib dependency and opens the model in the
locally installed OpenSCAD GUI. No local Docker installation is required.

## Maintenance

Update [`environment.yml`](environment.yml) to change tools, then rerun
`setup.ps1`. Keep the dependencies limited to shared CLI utilities and avoid
committing a machine-specific `conda env export`.
