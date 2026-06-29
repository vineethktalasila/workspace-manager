# Workspace Manager

An opinionated, deterministic workspace orchestrator for Zsh. 

Workspace Manager automates the friction out of complex research and computational workflows. It seamlessly bridges Conda environment provisioning, standardized directory scaffolding, isolated Git/SSH routing, and automated GitHub backups into a single, elegant `work` command.

## Features
* **Deterministic Scaffolding:** Instantly generate standardized data science and research directory topologies (`src/`, `data/`, `models/`, `notebooks/`) with customized `.gitignore` files.
* **Isolated Environment Provisioning:** Automatically clone and bind dedicated Conda environments to your projects, complete with auto-generated `.vscode/settings.json` integrations.
* **Hermetic Git Routing:** Dynamically inject local `user.name`, `user.email`, and distinct SSH keys into individual projects, keeping your professional repositories completely isolated from global system configs.
* **Automated Sync & Teardown:** Safely detach from a workspace. The `work stop` command automatically catches uncommitted changes, snapshots your Conda environment to an `environment.yml` blueprint, and synchronizes your work with a remote GitHub origin.
* **API Integration:** Publish private or public repositories directly to GitHub using the `gh` CLI during project creation.

---

## Prerequisites
This package is built natively for macOS and Unix environments running Zsh.
* **Zsh** (Default shell on macOS)
* **Conda** (Anaconda, Miniconda, or Miniforge)
* **Git** * **GitHub CLI** (`gh`) - *Required for remote publishing*

---

## Installation

**1. Clone the repository into your desired projects directory:**
```zsh
git clone git@github.com:vineethktalasila/workspace-manager.git ~/work/projects/workspace-manager
```

**2. Set up your local configuration:**
Copy the template configuration file to your home directory:
```zsh
cp ~/work/projects/workspace-manager/workspace.conf.template ~/.workspace.conf
```
Open `~/.workspace.conf` and update the environment variables with your specific system paths and Git identity.

**3. Load the plugin into your shell:**
Open your `~/.zshrc` file and append the following line at the bottom:
```zsh
source ~/work/projects/workspace-manager/workspace.plugin.zsh
```

**4. Reload your terminal:**
```zsh
source ~/.zshrc
```

---

## Configuration (`~/.workspace.conf`)

The system relies on a hidden configuration file to decouple the logic from hardcoded machine paths. 

```bash
# Core directories
export WS_HOME="$HOME/work"
export WS_PROJECTS="$WS_HOME/projects"

# Environment management
export WS_CONDA_BASE="$WS_HOME/conda_env"

# Git Identity (leave blank to use system defaults)
export WS_GIT_USER="Your Name"
export WS_GIT_EMAIL="your.email@example.com"

# Isolated SSH Tunneling (Optional)
export WS_SSH_KEY="$WS_HOME/.ssh/github_key"

# Hardware/Storage Parameters
export WS_BACKUP_MOUNT="/Volumes/work"
export WS_LOG_DIR="$WS_HOME/logs"
```

---

## Command Reference

The toolkit is accessed entirely through the `work` command. 

### `work new` (Project Scaffolding)
Architects a new project directory, provisions a Conda environment, establishes local Git configs, and creates IDE bindings.

**Options:**
* `--flat` : Bypass standard sub-directory generation (`data/`, `models/`, etc.) for a simpler layout.
* `--publish` : Automatically create a remote repository via GitHub API and push the initial commit.
* `--public` : Make the published repository public (defaults to private).
* `--clone <url>` : Bypass standard scaffolding to securely clone an existing remote repository into your workspace.

**Examples:**
```zsh
# Scaffold a standard directory for a new theoretical model
work new ksw_criterion_model

# Scaffold a flat topology and auto-publish privately to GitHub
work new --flat --publish grey_galaxies_sim

# Securely clone a colleague's repository into your managed workspace
work new --clone git@github.com:username/qft-analysis.git
```

### `work start` (Activation)
Activates a given workspace. It automatically hooks the designated Conda environment, navigates to the directory, and safely executes an inbound Git sync from the remote origin (and upstream, if applicable).

```zsh
# Activate a specific workspace directly
work start grey_galaxies_sim

# Or run without arguments to launch an interactive selection menu
work start
```

### `work change` (Transitioning)
A safe transition hook. It executes a full `work stop` teardown on your currently active environment before bootstrapping the new one. 

```zsh
work change supersym_blackholes
```

### `work stop` (Teardown & Outbound Sync)
Safely detaches from the current workspace. It exports your Conda blueprint to `environment.yml`, commits any unstaged work with an automated timestamp, pushes to your remote origin, deactivates the Conda environment, and returns you to `~/`.

```zsh
work stop
```

### `work delete` (Destructive Purge)
Mathematically purges a project from your workspace. It deletes the local APFS directory, permanently unlinks and destroys the Conda environment, and utilizes the GitHub API to delete the remote repository. *Requires strict user confirmation.*

```zsh
work delete obsolete_data_model
```

### `work list`
Displays a clean list of all currently managed project directories inside your configured `$WS_PROJECTS` path.

```zsh
work list
```

---

## Standard Directory Architecture
Unless bypassed with the `--flat` flag, `work new` generates the following deterministic structure optimized for Python workflows:

```text
project_name/
├── .vscode/               # Auto-configured Conda/Zsh IDE settings
├── data/
│   ├── processed/         # Cleaned, finalized data sets
│   └── raw/               # Immutable raw data
├── models/                # Trained models, neural network weights, etc.
├── notebooks/             # Jupyter/Mathematica scratchpads
├── src/                   # Core executable source code
├── tests/                 # Unit testing
├── .gitignore             # Opinionated data-science exclusions
└── README.md              
```
