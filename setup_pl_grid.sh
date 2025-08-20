#!/bin/bash

# Kolory terminala
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD='\033[1m'

MODULE_DIR="PL-GRID-SETUP"
RESOURCE_DIR="$MODULE_DIR/cyfronet_resources"
ENV_DIR="$MODULE_DIR/python_environments"

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

usage() {
    echo -e "${BOLD}Usage:${RESET} $0 -u <username> [-e <environment>] [-c <computer_unit>] [-g <groupname>]"
    echo "  -u, --username         (required) Username for the environment"
    echo "  -e, --environment      Environment type: 'conda' or 'venv' (default: venv)"
    echo "  -c, --computer_unit    Computer unit: 'ares' or 'athena' (default: ares)"
    echo "  -g, --groupname        Group name (default: plggiontracks)"
    echo "  -h, --help             Show this help message"
    exit 1
}

# Default values
ENVIRONMENT="venv"
COMPUTER_UNIT="ares"
GROUPNAME="plggiontracks"
USERNAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--username)
            USERNAME="$2"
            shift; shift
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift; shift
            ;;
        -c|--computer_unit)
            COMPUTER_UNIT="$2"
            shift; shift
            ;;
        -g|--groupname)
            GROUPNAME="$2"
            shift; shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error_exit "Unknown argument: $1"
            ;;
    esac
done

if [[ -z "$USERNAME" ]]; then
    log_error_exit "Username is required. Use -u <username>."
fi

log_info "Using username: $USERNAME"
log_info "Environment: $ENVIRONMENT"
log_info "Computer unit: $COMPUTER_UNIT"
log_info "Group name: $GROUPNAME"

# Make all setup scripts executable
log_info "Making setup scripts executable..."
chmod +x $ENV_DIR/.setup_conda.sh || log_error_exit "Failed to make .setup_conda.sh executable."
chmod +x $ENV_DIR/.setup_venv.sh || log_error_exit "Failed to make .setup_venv.sh executable."
chmod +x $RESOURCE_DIR/.setup_ares.sh || log_error_exit "Failed to make .setup_ares.sh executable."
chmod +x $RESOURCE_DIR/.setup_athena.sh || log_error_exit "Failed to make .setup_athena.sh executable."
log_success "Setup scripts are now executable."

project_dir="$PWD"
vscode_dir="$project_dir/.vscode"
tasks_file="$vscode_dir/tasks.json"
env_file="$project_dir/environment.yml"

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

# Choose and run the correct environment setup script with only --username as last flag
if [[ "$ENVIRONMENT" == "conda" ]]; then
    log_info "Running Conda setup script..."
    $ENV_DIR/.setup_conda.sh --username "$USERNAME" || log_error_exit "Failed to set up Conda environment."
    log_success "Conda environment set up successfully."
elif [[ "$ENVIRONMENT" == "venv" ]]; then
    log_info "Running venv setup script..."
    $ENV_DIR/.setup_venv.sh --username "$USERNAME" || log_error_exit "Failed to set up venv environment."
    log_success "venv environment set up successfully."
else
    log_error_exit "Unknown environment type: $ENVIRONMENT"
fi

if [[ -f "$tasks_file" ]]; then
    log_success "VSCode tasks file found at: $tasks_file"
    log_success "VSCode tasks configured successfully."
else
    log_warn "No tasks.json found. Creating one at: $tasks_file"
    mkdir -p "$vscode_dir"

    # Select the correct resource script for tasks.json
    if [[ "$COMPUTER_UNIT" == "ares" ]]; then
        RESOURCE_SCRIPT="cyfronet_resources/.setup_ares.sh"
    elif [[ "$COMPUTER_UNIT" == "athena" ]]; then
        RESOURCE_SCRIPT="cyfronet_resources/.setup_athena.sh"
    else
        log_error_exit "Unknown computer unit: $COMPUTER_UNIT"
    fi

    cat > "$tasks_file" <<EOF
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Install python env",
            "type": "shell",
            "command": "bash \"\${workspaceFolder}/PL-GRID-SETUP/$RESOURCE_SCRIPT\" --username $USERNAME",
            "windows": {
                "command": "bash \"\${workspaceFolder}/PL-GRID-SETUP/$RESOURCE_SCRIPT\" --username $USERNAME"
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

# Choose and run the correct resource setup script with only --username as last flag
if [[ "$COMPUTER_UNIT" == "ares" ]]; then
    log_info "Running ARES setup script..."
    $RESOURCE_DIR/.setup_ares.sh --username "$USERNAME" || log_error_exit "Failed to set up ARES environment."
    log_success "ARES environment set up successfully."
elif [[ "$COMPUTER_UNIT" == "athena" ]]; then
    log_info "Running ATHENA setup script..."
    $RESOURCE_DIR/.setup_athena.sh --username "$USERNAME" || log_error_exit "Failed to set up ATHENA environment."
    log_success "ATHENA environment set up successfully."
else
    log_error_exit "Unknown computer unit: $COMPUTER_UNIT"
fi