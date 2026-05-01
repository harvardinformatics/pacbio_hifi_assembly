#!/bin/bash

#SBATCH -N 1
#SBATCH -t 7-00:00:00
#SBATCH --mem 16G
#SBATCH -n 1
#SBATCH --partition intermediate
#SBATCH -J snakemake

# Activate python and your previously installed snakemake conda environment
module load python
conda activate snakemake

# Set env variable with path to the Cannon snakemake config for auto partition selection
SMK_PART_CFG="/n/holylfs05/LABS/informatics/Everyone/internal-share/cannon-snakemake-cfg/cannon-snakemake.yml"

# Run pipeline using desired resources set in ../profile/slurm and sample info in ../config/config.yaml
snakemake --use-conda --rerun-incomplete --slurm-partition-config $SMK_PART_CFG --workflow-profile ../profiles/slurm --configfile ../config/config.yaml -s Snakefile 