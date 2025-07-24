# PL-GRID-SETUP

Automated setup scripts to install and configure Conda environments on PL-GRID HPC clusters.

## Overview

This repository provides a set of shell scripts to quickly set up and configure Miniconda and Conda environments tailored for PL-GRID HPC clusters. It also installs helpful packages like Python, pip, and more.

## Usage

### 1. Clone your main repository and initialize `PL-GRID-SETUP` as a submodule

If your project doesn't already include `PL-GRID-SETUP` as a submodule, you can do the following:

```bash
# Clone your main repository with submodules
git clone --recurse-submodules https://github.com/yourusername/your-project.git
cd your-project

# (Optional) If PL-GRID-SETUP is not yet a submodule, add it
git submodule add https://github.com/RafalS3/PL-GRID-SETUP.git
git submodule update --init --recursive
```
### 2. Configure and run the set up

``` bash
# Edit the config file to set your PL-GRID username and group
nano config.json

# Run the setup script
./PL-GRID-SETUP/setup_pl_grid.sh
```
