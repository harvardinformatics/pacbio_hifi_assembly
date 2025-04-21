# pacbio_hifi_assembly
This pipeline automates via snakemake the genome assembly of PacBio HiFi reads using Hifiasm. It takes BAM files from sequencing as input and will output a final primary assembly plus two haplotype assemblies and basic assembly QC metrics from QUAST.  

## Getting the pipeline  
Simply clone this repository from Github, after making sure git is installed on your machine! (Note: if you are using the Harvard Canon computing cluster, git is installed by default):  

`git clone https://github.com/harvardinformatics/pacbio_hifi_assembly.git`  

Then enter the directory: `cd pacbio_hifi_assembly/`  

You will also need snakemake installed to run the pipeline. The easiest way to install snakemake is via Conda/Mamba (preferably Mamba), instructions for which can be found [here](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html). 

## Configuring the pipeline  
In the repo directory, there is a file in the `config/` subdirectory called `config.yaml` that you will need to modify to point towards your data. For a basic assembly, just change the following lines: 

```
sample: "sample_name"  #Name of the sample to act as base name
reads: " "  #List of BAM files output from sequencer (include full path). If multiple files, separate by SPACES
```

You do not need to change any other options in `config/config.yaml` unless you are incorporating HiC data (note this is NOT the same as scaffolding with HiC!) and/or Nanopore long reads.  

## Running the pipeline  
From the main directory, navigate into the `workflow/` subdirectory, which contains the `Snakefile` that determines the order in which the pipeline runs. For running the assembly on the cluster, here is an example SLURM file to run from within the `workflow` directory:

```
#!/bin/bash

#SBATCH -N 1
#SBATCH -t 7-00:00:00
#SBATCH --mem 16G
#SBATCH -n 1
#SBATCH --partition intermediate
#SBATCH -J snakemake

source /n/holylfs05/LABS/informatics/Users/dkhost/mamba/bin/activate snakemake

snakemake --rerun-incomplete --profile ../profiles/slurm
```  

Resources needed will depend on the size and complexity of the genome, as will the time to complete. If successful, you should see a subdirectory `workflow/results/` that contains the finished assembly and QC stats!  