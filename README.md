<p align="center">
  <img src="https://github.com/user-attachments/assets/aca97635-c3ce-4e95-8535-92a65a7ef0eb" alt="HPC Logo" width="400" />
</p>

# easyHPC!
## Overview

This repository provides a set of shell scripts to quickly set up and configure Python environments (using either Conda or venv) tailored for PL-GRID HPC clusters. It supports both Ares and Athena units, and can install helpful packages like Python, pip, and more.

## Usage

### 1. Clone your main repository and initialize `easyHPC` as a submodule

If your project doesn't already include `easyHPC` as a submodule, you can do the following:

```bash
# Clone your main repository with submodules
git clone --recurse-submodules https://github.com/yourusername/your-project.git
cd your-project

# (Optional) If easyHPC is not yet a submodule, add it
git submodule add https://github.com/RafalS3/easyHPC.git
git submodule update --init --recursive
```

### 2. Configure and run the setup


## Quickstart: Choose your setup

Replace `your_plgrid_username` with your actual PL-GRID username. You can copy and paste the command for your desired environment and cluster:

**Ares + Conda:**
```bash
./PL-GRID-SETUP/setup_pl_grid.sh --environment conda --computer_unit ares --username <your_plgrid_username>
```

**Ares + venv:**
```bash
./PL-GRID-SETUP/setup_pl_grid.sh --environment venv --computer_unit ares --username <your_plgrid_username>
```

**Athena + Conda: (resolving Conda environment with PyTorch or simillar could take really, really long time)**
```bash
./PL-GRID-SETUP/setup_pl_grid.sh --environment conda --computer_unit athena --username <your_plgrid_username>
```

**Athena + venv:**
```bash
./PL-GRID-SETUP/setup_pl_grid.sh --environment venv --computer_unit athena --username <your_plgrid_username>
```

This will:
- Choose the correct resource script for Ares or Athena
- Choose the correct environment setup (Conda or venv)
- Create or update `environment.yml` as needed
- Generate a VSCode `tasks.json` for your selected cluster

## Troubleshooting & Requirements

- Ensure you have `MEMFS` set to a writable directory in memory.
- Ensure your project contains the correct environment file (required for custom environments; if missing, an empty venv will be created):
  - For **conda**: `environment.yml`,
  - For **venv**: `requirements.txt`.

## Configuration options (for setup_pl_grid.sh only)

- `--username <username>`: Your PL-GRID username (required, must be last flag)
- `--environment <conda|venv>`: Choose your preferred Python environment manager (default: venv)
- `--computer_unit <ares|athena>`: Choose the target cluster (default: ares)

---
For more details, see the comments in each script.
