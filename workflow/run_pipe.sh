#!/bin/bash
set -euo pipefail

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    echo "This launcher should be run directly on a login node, not with sbatch." >&2
    echo "Run: bash workflow/run_pipe.sh" >&2
    echo "The Snakemake SLURM executor will submit the rule jobs to the cluster." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate python and your previously installed snakemake conda environment
source /n/holylfs05/LABS/informatics/Users/dkhost/mamba/bin/activate snakemake

# Set env variable with path to the Cannon snakemake config for auto partition selection
SMK_PART_CFG="/n/holylfs05/LABS/informatics/Everyone/internal-share/cannon-snakemake-cfg/cannon-snakemake.yml"

# Run pipeline using desired resources set in ../profiles/slurm and sample info in ../config/config_test.yaml
snakemake \
    --use-conda \
    --rerun-incomplete \
    --latency-wait 60 \
    --slurm-partition-config "$SMK_PART_CFG" \
    --workflow-profile ../profiles/slurm \
    --configfile ../config/config_test.yaml \
    -s Snakefile \
    "$@"
