# Workspace Manager

## Overview
Workspace Manager is a Zsh-first project workflow wrapper exposed through a single `work` command. 

It combines:
- Project creation, cloning, and upstream forking
- Context-aware Zsh autocomplete for projects and subcommands
- Per-project Git identity and SSH key routing
- Optional Conda environment provisioning
- Session-scoped workspace activation and teardown
- Project listing and destructive cleanup

The CLI routing behavior is decoupled across:
- `bin/work`: Core router for executing heavy subcommands in isolated sub-shells.
- `workspace.plugin.zsh`: Shell function wrapper sourced directly into memory to handle state-mutating commands (`start`, `stop`, `change`) and Zsh `compdef` autocomplete.

## Installation

```zsh
curl -fsSL [https://raw.githubusercontent.com/vineethktalasila/workspace-manager/main/install.sh](https://raw.githubusercontent.com/vineethktalasila/workspace-manager/main/install.sh) | zsh
```

What `install.sh` does:
1. Ensures `git` is available.
2. Clones or updates this repository into a hidden system directory: `$HOME/.workspace-manager`.
3. Copies `workspace.conf.template` to `~/.workspace.conf` (if it does not exist) and securely injects the `$WS_CORE_DIR` system path.
4. Appends `source $HOME/.workspace-manager/workspace.plugin.zsh` to `~/.zshrc`.

After install:
1. Edit `~/.workspace.conf` to set your desired project paths and Git identity.
2. Reload your shell (`source ~/.zshrc` or `work-reload`) or restart your terminal.

## Configuration
Configuration is loaded from `~/.workspace.conf`. The core logic securely separates *where the tool lives* (`$WS_CORE_DIR`) from *where your work lives* (`$WS_PROJECTS`).

Template schema:

```bash
export WS_HOME="$HOME/work"
export WS_PROJECTS="$WS_HOME/projects"
export WS_CONDA_BASE="$WS_HOME/conda_env"
export WS_GIT_USER="Your Name"
export WS_GIT_EMAIL="your.email@example.com"
export WS_SSH_KEY="$WS_HOME/.ssh/github_key"
```

Variable reference:
- `WS_PROJECTS`: Parent directory containing all managed project folders. You can place this anywhere (e.g., an external drive).
- `WS_CONDA_BASE`: Base directory where Conda environments are expected (`$WS_CONDA_BASE/envs/<project>`).
- `WS_GIT_USER`: Per-project Git `user.name` applied during project creation/clone.
- `WS_GIT_EMAIL`: Per-project Git `user.email` applied during project creation/clone.
- `WS_SSH_KEY`: Optional SSH key path used for Git operations (`GIT_SSH_COMMAND` and local `core.sshCommand`).
- `WS_CORE_DIR`: **(Auto-injected by installer)** The hidden path where the CLI binaries live. 

## Command Reference
The main command is:

```zsh
work <subcommand> [options]
```
*Note: Press `<Tab>` after typing `work start`, `stop`, `change`, or `delete` for dynamic, context-aware project name autocompletion.*

### `work new`
Routes to `bin/create_project.sh`.

Usage examples:

```zsh
# Standard scaffold
work new my_project

# Flat scaffold (skip data/raw, notebooks, src, models, tests)
work new --flat my_project

# Scaffold and publish to GitHub as private repo (requires gh CLI)
work new --publish my_project

# Clone mode (name + remote URL)
work new --clone my_project git@github.com:owner/repo.git

# Fork mode (Clones upstream, sets upstream remote, and optionally publishes personal fork to origin)
work new --fork --publish my_project [https://github.com/OriginalDev/their-repo.git](https://github.com/OriginalDev/their-repo.git)
```

Behavior details:
- Creates project at `$WS_PROJECTS/<project_name>`.
- If `conda` is available, clones `base` into a new environment named after the project.
- Generates `.gitignore`, `.vscode/settings.json`, and project `README.md`.
- Applies local Git identity and SSH configuration using `WS_GIT_USER`, `WS_GIT_EMAIL`, `WS_SSH_KEY`.
- **Fork Mode:** Renames the cloned remote to `upstream` and uses `gh` to provision your personal fork as `origin`.

### `work delete`
Routes to `bin/delete_project.sh`.

Usage example:

```zsh
work delete my_project
```

Behavior details:
- Requires exact confirmation by typing the project name.
- Removes local directory at `$WS_PROJECTS/<project_name>`.
- Removes Conda environment `<project_name>`.
- If `gh` is installed, attempts to delete the remote repo using `gh repo delete <project_name> --yes`.

### `work list`
Implemented directly inside `bin/work`.

Usage example:

```zsh
work list
```

Behavior details:
- Prints a cleanly formatted list of directories found under `$WS_PROJECTS`.

### `work start`
Intercepted by `workspace.plugin.zsh` and routed to `bin/start.zsh`.

Usage examples:

```zsh
# Activate specific workspace
work start my_project

# Interactive selection (lists projects with matching Conda envs)
work start
```

Behavior details:
- Sets the `$WS_ACTIVE_PROJECT` session variable to lock the terminal to the selected workspace.
- Activates Conda environment with the same name.
- `cd` into the project directory.
- Pulls from `origin` on the active branch and automatically checks for/merges updates from `upstream` (if a fork).

### `work stop`
Intercepted by `workspace.plugin.zsh` and routed to `bin/stop.zsh`.

Usage example:

```zsh
work stop
```

Behavior details:
- Reads the `$WS_ACTIVE_PROJECT` session variable to cleanly target the current terminal's workspace in an $O(1)$ operation.
- Exports the active Conda environment to `environment.yml`.
- Auto-commits and pushes local modifications to `origin` with an automated teardown timestamp.
- Deactivates Conda shells, unsets session variables, and returns to the home directory.

### `work change`
Intercepted by `workspace.plugin.zsh`.

Usage example:

```zsh
work change target_project
```

Behavior details:
- Safely transitions workspace topology by executing `work stop` on the current project, followed seamlessly by `work start target_project`.

### `work backup`
Routes to `bin/backup_workspace.sh`.

Usage example:

```zsh
work backup
```

Behavior details:
- Acts as a global safety net, scanning all projects in `$WS_PROJECTS` and performing a batch sync/push operation for any dirty repositories left open in other terminals.

## Developer Tools
- `work-reload`: A hidden alias that hot-reloads `workspace.plugin.zsh` and rebuilds the Zsh `compdef` autocomplete index without restarting the terminal session.