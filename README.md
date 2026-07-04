# Workspace Manager

## Overview
Workspace Manager is a Zsh-first project workflow wrapper exposed through a single `work` command.

It combines:
- Project creation and cloning
- Per-project Git identity and SSH key routing
- Optional Conda environment provisioning
- Workspace activation/deactivation helpers
- Project listing and destructive teardown

The CLI routing behavior is split across:
- `bin/work`: core router for subcommands
- `workspace.plugin.zsh`: shell function wrapper that intercepts `start`, `stop`, and `change`

## Installation
```zsh
curl -fsSL https://raw.githubusercontent.com/vineethktalasila/workspace-manager/main/install.sh | zsh
```

What `install.sh` does:
1. Ensures `git` is available.
2. Clones or updates this repo at `$HOME/work/projects/workspace-manager`.
3. Copies `workspace.conf.template` to `~/.workspace.conf` if it does not exist.
4. Appends `source $HOME/work/projects/workspace-manager/workspace.plugin.zsh` to `~/.zshrc`.

After install:
1. Edit `~/.workspace.conf`.
2. Reload shell (`source ~/.zshrc`) or restart terminal.

## Configuration
Configuration is loaded from `~/.workspace.conf`.

Template schema:

```bash
export WS_HOME="$HOME/work"
export WS_PROJECTS="$WS_HOME/projects"
export WS_CONDA_BASE="$WS_HOME/conda_env"
export WS_GIT_USER="Your Name"
export WS_GIT_EMAIL="your.email@example.com"
export WS_SSH_KEY="$WS_HOME/.ssh/github_key"
export WS_BACKUP_MOUNT="/Volumes/work"
export WS_LOG_DIR="$WS_HOME/logs"
```

Variable reference:
- `WS_HOME`: Root workspace directory.
- `WS_PROJECTS`: Parent directory containing all managed project folders.
- `WS_CONDA_BASE`: Base directory where Conda environments are expected (`$WS_CONDA_BASE/envs/<project>`).
- `WS_GIT_USER`: Per-project Git `user.name` applied during project creation/clone.
- `WS_GIT_EMAIL`: Per-project Git `user.email` applied during project creation/clone.
- `WS_SSH_KEY`: Optional SSH key path used for Git operations (`GIT_SSH_COMMAND` and local `core.sshCommand`).
- `WS_BACKUP_MOUNT`: Reserved in template; currently not consumed by the core router.
- `WS_LOG_DIR`: Reserved in template; currently not consumed by the core router.

Important path note:
- `install.sh` installs to `$HOME/work/projects/workspace-manager`.
- `workspace.plugin.zsh` and `bin/work` resolve helper scripts via `$WS_PROJECTS/workspace-manager/...`.
- Keep `WS_PROJECTS` aligned with install location, or commands may resolve to the wrong path.

## Command Reference
The main command is:

```zsh
work <subcommand> [options]
```

Subcommands defined in `bin/work`:

### `work new`
Routes to `bin/create_project.sh`.

Usage examples:

```zsh
# Standard scaffold
work new my_project

# Flat scaffold (skip data/raw, data/processed, notebooks, src, models, tests)
work new --flat my_project

# Scaffold and publish to GitHub as private repo (requires gh)
work new --publish my_project

# Scaffold and publish as public repo
work new --publish --public my_project

# Clone mode (name + remote URL)
work new --clone my_project git@github.com:owner/repo.git
```

Behavior details:
- Creates project at `$WS_PROJECTS/<project_name>`.
- If `conda` is available, clones `base` into a new environment named after the project.
- Generates `.gitignore`, `.vscode/settings.json`, and project `README.md`.
- Initializes Git and performs initial commit.
- Applies local Git identity and SSH configuration using `WS_GIT_USER`, `WS_GIT_EMAIL`, `WS_SSH_KEY`.

### `work delete`
Routes to `bin/delete_project.sh`.

Usage example:

```zsh
work delete my_project
```

Behavior details:
- Requires exact confirmation by typing project name.
- Removes local directory at `$WS_PROJECTS/<project_name>`.
- Removes Conda environment `<project_name>` when Conda is available.
- If `gh` is installed, attempts to delete remote repo using `gh repo delete <project_name> --yes`.

### `work list`
Implemented directly inside `bin/work`.

Usage example:

```zsh
work list
```

Behavior details:
- Prints directories found under `$WS_PROJECTS`.

### `work start`
Recognized by `bin/work`, but practically handled by `workspace.plugin.zsh` by sourcing `bin/start.zsh`.

Usage examples:

```zsh
# Activate specific workspace
work start my_project

# Interactive selection (lists projects with matching Conda envs)
work start
```

Behavior details (`bin/start.zsh`):
- Selects workspace (argument or interactive menu).
- Activates Conda environment with same name (if Conda exists).
- `cd` into project directory.
- Pulls from `origin` on active branch and optionally merges `upstream/<branch>`.

### `work stop`
Recognized by `bin/work`, but practically handled by `workspace.plugin.zsh` by sourcing `bin/stop.zsh`.

Usage example:

```zsh
work stop
```

Behavior details (`bin/stop.zsh`):
- Iterates repos under `$WS_PROJECTS`.
- Exports Conda environment to each repo's `environment.yml` when possible.
- Auto-commits and pushes dirty repos with an automated teardown commit message.
- Deactivates active Conda shells and returns to home directory.

### `work change`
Recognized by `bin/work`, but practically handled by `workspace.plugin.zsh`.

Usage example:

```zsh
work change my_project
```

Behavior details:
- Prints transition banner.
- Sources `bin/stop.zsh` then `bin/start.zsh <target>`.

### `work backup`
Recognized in `bin/work` but currently not implemented.

Usage example:

```zsh
work backup
```

Current output:

```text
Subcommand 'backup' is recognized and will be fully integrated soon.
```

## Notes
- `work --help` is not currently implemented in `bin/work`.
- `start`, `stop`, and `change` rely on the shell plugin wrapper, not only the router binary.
