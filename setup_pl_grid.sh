#!/bin/bash

# Kolory terminala
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD='\033[1m'

log_info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error_exit() {
    echo -e "${RED}[ERROR]${RESET} $1"
    exit 1
}

log_info "Making setup scripts executable..."
chmod +x .setup_conda.sh || log_error_exit "Failed to make setup_conda.sh executable."
chmod +x .setup_ares.sh || log_error_exit "Failed to make setup_ares.sh executable."
log_success "Setup scripts are now executable."

project_dir="$PWD"
vscode_dir="$project_dir/.vscode"
tasks_file="$vscode_dir/tasks.json"
env_file="$project_dir/environment.yml"

if find config.json -type f -print -quit | grep -q .; then
    log_success "config.json file found."
else
    log_error_exit "config.json file not found. Please create it before running the script."
fi

log_info "Extracting username from config.json..."
USERNAME=$(grep -oP '"username"\s*:\s*"\K[^"]+' config.json)
log_success "Username extracted: $USERNAME"

if [[ -f "$env_file" ]]; then
    log_success "environment.yml file found at: $env_file"
else
    log_warn "No environment.yml found. Creating one at: $env_file"
    touch "$env_file" || log_error_exit "Failed to create environment.yml file."

    echo "name: $USERNAME
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - click=8.1.7
  - pytables=3.10.2
  - pyarrow
  - pip
  - poetry
  - ipykernel" >> "$env_file" || log_error_exit "Failed to write to environment.yml file."

    log_success "environment.yml file created successfully."
fi

log_info "Running Conda setup script..."
./.setup_conda.sh || log_error_exit "Failed to set up Conda environment."
log_success "Conda environment set up successfully."

if [[ -f "$tasks_file" ]]; then
    log_success "VSCode tasks file found at: $tasks_file"
    log_success "VSCode tasks configured successfully."
else
    log_warn "No tasks.json found. Creating one at: $tasks_file"
    mkdir -p "$vscode_dir"

    cat > "$tasks_file" <<EOF
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Install python env",
            "type": "shell",
            "command": "bash \"\${workspaceFolder}/.setup_ares.sh\"",
            "windows": {
                "command": "bash \"\${workspaceFolder}/.setup_ares.sh\""
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "new"
            },
            "runOptions": {
                "runOn": "folderOpen"
            }
        }
    ]
}
EOF

    log_success "Created default tasks.json at: $tasks_file"
fi

log_info "Running ARES setup script..."
./.setup_ares.sh || log_error_exit "Failed to set up environment."
log_success "environment set up successfully."
