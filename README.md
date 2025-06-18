# pacbio_hifi_assembly
This pipeline automates via snakemake the genome assembly of PacBio HiFi reads using Hifiasm. It takes BAM files from sequencing as input and will output a final primary assembly plus two haplotype assemblies and basic assembly QC metrics from QUAST.  

## Getting the pipeline  
Simply clone this repository from Github, after making sure git is installed on your machine! (Note: if you are using the Harvard Canon computing cluster, git is installed by default):  

`git clone https://github.com/harvardinformatics/pacbio_hifi_assembly.git`  

Then enter the directory: `cd pacbio_hifi_assembly/`  

You will also need snakemake installed to run the pipeline. The easiest way to install snakemake is via Conda/Mamba (preferably Mamba), instructions for which can be found [here](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html). In addition, in order to use cluster integration, snakemake v8+ requires a separate [executor plugin](https://anaconda.org/bioconda/snakemake-executor-plugin-slurm) to be installed. You can use conda to install this in the same conda environment that you installed snakemake in.

## Configuring the pipeline  
In the repo directory, there is a file in the `config/` subdirectory called `config.yaml` that you will need to modify to point towards your data. For a basic assembly, just change the following lines: 

```
samples:
  sampleA: ["path/to/reads"]
  sampleB: ["path/to/reads", "/path/to/reads2"]
```

 Here, "sampleA" and "sampleB" are the prefixes for each sample and will be used to name the output assembly files, so change them to whatever you like. You can have as many samples as you like, just add another tab-indented line with the sample name and path to the reads. For each sample, add the path to the BAM HiFi reads (enclosed in brackets and quotes, as shown above); if you have multiple BAM files for a single sample, separate the paths with commas. So, for example a workflow doing four different assemblies with a varying number of input BAM files:

 ```
 samples:
  laysanAlbatross: ["data/m84147_250418_160915_s1.hifi_reads.bc1019.bam", "data/m84147_250502_200658_s1.hifi_reads.bc1019.bam"]
  stAlbatross: ["data/m84147_250418_181221_s2.hifi_reads.bc1022.bam", "data/m84147_250502_200658_s1.hifi_reads.bc1022.bam"]
  wavedAlbatross: ["data/m84147_250418_181221_s2.hifi_reads.bc1021.bam", "data/m84147_250502_200658_s1.hifi_reads.bc1021.bam"]
  bfAlbatross: ["data/m84147_250418_160915_s1.hifi_reads.bc1020.bam"]
 ```

You do not need to change any other options in `config/config.yaml` unless you are incorporating HiC data (note this is NOT the same as scaffolding with HiC!) and/or Nanopore long reads.

## Setting resources
This workflow uses a workflow-specific profile that configures the resources given to each step of the pipeline. Resources needed will depend on the size and complexity of the genome, though the step that will be the most variable between users is likely only the actual `hifiasm` assembly step, and other steps won't require much tweaking of resources.

Resources are defined in the `profile/slurm/config.yaml` file. The only line you need to change is the `slurm_account` line, where you should set it to your Cannon cluster account. If you are running into memory issues with the any given step, you can increase the amount of RAM allocated by changing the `mem_mb` line. 

## Running the pipeline  
From the main directory, navigate into the `workflow/` subdirectory, which contains the `Snakefile` that determines the order in which the pipeline runs. Before you run the pipeline for real, it can be useful to first do a "dry run" to make sure the pipeline is configured properly and all the files are accessible:

`snakemake --dry-run --profile ../profiles/slurm`

If this works, you should see a table summarizing number of jobs that will be submitted along with some text saying "This was a dry-run." If it worked, you are good to submit it to the cluster.

For running the assembly on the cluster, here is an example SLURM file to run from within the `workflow` directory:

```
#!/bin/bash

#SBATCH -N 1
#SBATCH -t 7-00:00:00
#SBATCH --mem 16G
#SBATCH -n 1
#SBATCH --partition intermediate
#SBATCH -J snakemake

#Activate python and your previously installed snakemake conda environment
module load python
mamba activate snakemake

snakemake --use-conda --rerun-incomplete --profile ../profiles/slurm
```  

This script will submit a "head" job that runs for the entire length of the pipeline and coordinates submission of each step of the pipeline as individual SLURM jobs. If successful, you should see a subdirectory `workflow/results/` that contains the finished assembly and QC stats!  