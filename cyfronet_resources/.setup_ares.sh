#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

log_info "Loading Miniconda3 module..."
module load miniconda3 || log_error_exit "Failed to load miniconda3 module."
log_success "Miniconda3 module loaded successfully."

log_info "Parsing config.json..."





usage() {
    echo -e "${BOLD}Usage:${RESET} $0 --username <username>"
    echo "  --username <username>   (required, must be last)"
    echo "  -h, --help              Show this help message"
    exit 1
}


USERNAME=""

# Parse command line arguments

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --username)
            USERNAME="$2"
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

# Check required
if [[ -z "$USERNAME" ]]; then
    log_error_exit "Username is required. Use -u <username>."
fi

# Check PLG_GROUPS_STORAGE
if [ -z "$PLG_GROUPS_STORAGE" ]; then
    log_error_exit "PLG_GROUPS_STORAGE is not set. Please set PLG_GROUPS_STORAGE before running the script."
fi

if [ -n "$MEMFS" ]; then
    log_info "MEMFS is set to: $MEMFS"


    HOME_SRC_PATH="$HOME/$USERNAME.sqsh"
    DEST_PATH="$MEMFS/$USERNAME.sqsh"
    ENV_PATH="$MEMFS/envs/$USERNAME"

        if [ -f "$HOME_SRC_PATH" ]; then
            log_success "Found $USERNAME.sqsh in HOME directory: $HOME_SRC_PATH"
            SRC_PATH="$HOME_SRC_PATH"
        else
            log_error_exit "$USERNAME.sqsh not found in HOME directory."
        fi

    if mountpoint -q "$ENV_PATH"; then
        log_warn "Squashfs already mounted at $ENV_PATH. Unmounting..."
        fusermount -u "$ENV_PATH" || log_error_exit "Failed to unmount squashfs."
        log_success "Squashfs unmounted successfully."
    fi

    if [ -d "$ENV_PATH" ]; then
        log_info "Removing existing directory at $ENV_PATH..."
        rm -rf "$ENV_PATH" || log_error_exit "Failed to remove existing directory."
        log_success "Directory removed successfully."
    fi

    log_info "Copying $SRC_PATH to $DEST_PATH..."
    cp "$SRC_PATH" "$DEST_PATH" || log_error_exit "Failed to copy squashfs file."
    log_success "File copied successfully."

    log_info "Creating directory $ENV_PATH..."
    mkdir -p "$ENV_PATH" || log_error_exit "Failed to create environment directory."
    log_success "Directory created."

    log_info "Mounting squashfs file..."
    squashfuse "$DEST_PATH" "$ENV_PATH" || log_error_exit "Failed to mount squashfs file."
    log_success "Squashfs file mounted successfully."

    log_info "Initializing conda..."
    eval "$(conda shell.bash hook)" || log_error_exit "Failed to initialize conda."
    log_success "Conda initialized."

    log_info "Activating conda environment at $ENV_PATH..."
    conda activate "$ENV_PATH" || log_error_exit "Failed to activate conda environment."
    log_success "Conda environment activated."

    log_info "Appending MEMFS environment directories to conda config..."
    conda config --append envs_dirs "$MEMFS/envs" || log_error_exit "Failed to update conda configuration."
    log_success "Conda configuration updated."

    export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH

else
    log_error_exit "MEMFS is not set. Please set MEMFS before running the script."
fi

# ---------------------------------------------------
echo -e "${BOLD}${GREEN}✔ Setup completed successfully.${RESET}"
