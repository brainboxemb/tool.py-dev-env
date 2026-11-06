# tool.py-dev-env

Version-controlled Conda environment for **shared Python development tools and utilities**.

The repository stores only the **environment definition**; the installed
environment lives locally on Windows. It is not part of the OpenSCAD model
archive and is unrelated to the CI Docker images.

## Purpose

One reusable Conda environment named **`brainboxemb-dev-tools`** for command-line
developer utilities shared by multiple repositories. The initial tool is
[vcs2l](https://github.com/ros-infrastructure/vcs2l), which checks out the
pinned external dependencies described in a project's `dependencies.repos`.

Project-specific Python runtimes and packages should stay in their own
environments instead of accumulating here.

## Install on Windows

### 1. Install or upgrade Conda

Use an existing Miniconda, Miniforge or Anaconda installation. On Windows,
Miniconda can be managed by [Chocolatey](https://community.chocolatey.org/packages/miniconda3).
Check whether Chocolatey already manages it:

```powershell
choco list --limit-output | Select-String "miniconda|miniforge|anaconda"
```

When Chocolatey manages `miniconda3`, upgrade from an **administrator
PowerShell**:

```powershell
choco upgrade miniconda3 -y
```

If it is not installed, `choco install miniconda3 -y` is an option.
An upgrade may replace the existing installation directory: check and back up
any environments you need to keep **before** upgrading.

After installation, use a **new terminal** and verify the installed Python
can load OpenSSL (the base Python version need not match the environment below):

```powershell
& "C:\tools\miniconda3\python.exe" --version
& "C:\tools\miniconda3\python.exe" -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

The `C:\tools\miniconda3` path is an example used on this machine;
adjust it if Miniconda was installed elsewhere. The SSL check must succeed
before Conda can download packages over HTTPS.

### 2. Create or update the development environment

Clone this repository and run from its root in **VS Code PowerShell**:

```powershell
.\scripts\setup.ps1
```

The script creates or updates `brainboxemb-dev-tools` from
[`environment.yml`](environment.yml) and checks the `vcs` command.
**You do not have to activate `base` first.**

### How the setup script works

`scripts/setup.ps1` has PowerShell comment-based help (`Get-Help .\scripts\setup.ps1 -Full`).
It performs only three operations:

1. Find the **real `conda.exe`** (not the interactive PowerShell `conda` hook).
2. Run `conda env update --name brainboxemb-dev-tools --file environment.yml --prune`.
   This creates the environment if it is missing, or updates it if it exists.
3. Check `vcs --help` inside the environment via `conda run`.

There is **no JSON parsing or environment-list bookkeeping**. The script never
changes PATH, your PowerShell profile or VS Code's selected interpreter.
It recognizes common installations, including `C:\tools\miniconda3`.
For a custom installation, specify the executable explicitly:

```powershell
.\scripts\setup.ps1 -CondaExe "D:\tools\miniconda3\Scripts\conda.exe"
```

Selecting a Python interpreter in VS Code is a separate action: after setup,
use **Ctrl+Shift+P → Python: Select Interpreter** and select
`brainboxemb-dev-tools`. Conda does not need to be initialized in the terminal
just to run the setup script.

Without the script, the equivalent initial installation is:

```powershell
conda env create -f environment.yml
```

Later, after pulling changes to this repository:

```powershell
conda env update --name brainboxemb-dev-tools --file environment.yml --prune
```

If `conda activate` does not work in PowerShell, use
`conda init powershell` **once**, then restart the terminal. This changes
your shell initialization only; it is not done by the setup script.

## VS Code

After setup, select the interpreter with **Ctrl+Shift+P → Python: Select
Interpreter → brainboxemb-dev-tools**. Close any old integrated terminal and
open a new one. Selecting the interpreter is **not** the same as initializing
the Conda command in PowerShell; automatic terminal activation depends on the
VS Code Python extension and the shell setup.

To activate the environment explicitly in an integrated PowerShell terminal:

```powershell
& "C:\tools\miniconda3\shell\condabin\conda-hook.ps1"
conda activate brainboxemb-dev-tools
vcs --help
```

If you want `conda activate` to work automatically in future PowerShell
sessions, run `conda init powershell` once in an initialized Conda prompt,
then restart VS Code. This is optional; the setup script itself uses
`conda.exe` directly and does not modify your profile or PATH.

**Git actions in VS Code do not need Python.** VS Code Source Control uses
Git directly. Choose a Python interpreter only when you need to run Python
code or tools in that environment.

## Troubleshooting

### Conda shows `HTTP 000 CONNECTION FAILED`

Check whether **the Conda base Python** can load OpenSSL:

```powershell
& "C:\tools\miniconda3\python.exe" -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

If this fails with `ImportError: DLL load failed while importing _ssl`,
Conda cannot make HTTPS requests. This is different from a certificate
verification error. Check whether the installation is properly activated and
whether its OpenSSL DLLs are present under `Library\bin`. If the installation
is old or damaged, upgrade/reinstall Miniconda; **do not disable SSL
verification** as a workaround.

If `curl.exe -I https://conda.anaconda.org/conda-forge/win-64/repodata.json`
returns HTTP 200, that confirms Windows HTTPS works, but **does not prove
Conda's Python/OpenSSL works**.

### Chocolatey upgrade fails after uninstalling old Miniconda

An interrupted upgrade may remove the old directory while Chocolatey still
lists the old package version. Check:

```powershell
Test-Path "C:\tools\miniconda3"
choco list --limit-output | Select-String "miniconda"
```

If the old install directory is gone, retry `choco upgrade miniconda3 -y`
from an administrator PowerShell. If it fails again, inspect
`C:\ProgramData\chocolatey\logs\chocolatey.log` before doing any manual
cleanup. Check for important Conda environments/backups before deleting files.

### `ConvertFrom-Json` fails in an older setup script

Earlier versions queried `conda env list --json` through the PowerShell
`conda` hook. The current script avoids JSON entirely and invokes
`conda.exe` directly. Update your local checkout if you still see the
`ConvertFrom-Json` line.

## Example: OpenSCAD model archive

In the local clone of
[`2026-011-01.cad.model-archive`](https://github.com/brainboxemb/2026-011-01.cad.model-archive):

```powershell
conda activate brainboxemb-dev-tools
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
.\scripts\open-model.ps1
```

This fetches the repository-pinned NopSCADlib checkout and opens the example
in your **locally installed OpenSCAD GUI**. No Docker or local documentation
generation is needed.

Alternatively, without activating the environment:

```powershell
conda run -n brainboxemb-dev-tools vcs import --input dependencies.repos ext
```

## Maintenance

`environment.yml` is the editable, version-controlled source of truth.
Keep dependencies narrow and pin important CLI versions. Do **not**
commit the output of `conda env export`: it would capture large amounts
of machine-specific, transitive dependency information.

The `brainboxemb-dev-tools` name is intentionally stable across projects. CI builds
use their own containers/environments and do not depend on this local one.
