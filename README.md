# tool.py-dev-env

Version-controlled Conda environment for **shared Python development tools and utilities**.

The repository stores only the **environment definition**; the installed
environment lives locally on Windows. It is not part of the OpenSCAD model
archive and is unrelated to the CI Docker images.

## Purpose

One reusable Conda environment named **`dev-tools`** for command-line
developer utilities shared by multiple repositories. The initial tool is
[vcs2l](https://github.com/ros-infrastructure/vcs2l), which checks out the
pinned external dependencies described in a project's `dependencies.repos`.

Project-specific Python runtimes and packages should stay in their own
environments instead of accumulating here.

## Install on Windows

Prerequisite: Conda available in PowerShell. A minimal installation such as
[Miniforge](https://github.com/conda-forge/miniforge) is suitable; Anaconda
or Miniconda can also be used.

Clone this repository. From its root in PowerShell:

```powershell
.\scripts\setup.ps1
```

The script creates `dev-tools` if needed, or updates it from
[`environment.yml`](environment.yml) if it already exists.
It checks that the `vcs` command is available in the environment.

Without the script, the equivalent initial installation is:

```powershell
conda env create -f environment.yml
```

Later, after pulling changes to this repository:

```powershell
conda env update --name dev-tools --file environment.yml --prune
```

If `conda activate` does not work in PowerShell, use
`conda init powershell` **once**, then restart the terminal. This changes
your shell initialization only; it is not done by the setup script.

## VS Code

Open an integrated PowerShell terminal and run:

```powershell
conda activate dev-tools
vcs --help
```

If you are developing **Python code**, choose the interpreter using
**Python: Select Interpreter** and select `dev-tools`.

**Git actions in VS Code do not need Python.** VS Code Source Control uses
Git directly. Interpreter selection is only relevant when running Python
code or terminals where the Conda environment is active.

## Example: OpenSCAD model archive

In the local clone of
[`2026-011-01.cad.model-archive`](https://github.com/brainboxemb/2026-011-01.cad.model-archive):

```powershell
conda activate dev-tools
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
.\scripts\open-model.ps1
```

This fetches the repository-pinned NopSCADlib checkout and opens the example
in your **locally installed OpenSCAD GUI**. No Docker or local documentation
generation is needed.

Alternatively, without activating the environment:

```powershell
conda run -n dev-tools vcs import --input dependencies.repos ext
```

## Maintenance

`environment.yml` is the editable, version-controlled source of truth.
Keep dependencies narrow and pin important CLI versions. Do **not**
commit the output of `conda env export`: it would capture large amounts
of machine-specific, transitive dependency information.

The `dev-tools` name is intentionally stable across projects. CI builds
use their own containers/environments and do not depend on this local one.
