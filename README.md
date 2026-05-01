# pacbio_hifi_assembly
This pipeline automates via snakemake the genome assembly of PacBio HiFi and Oxford Nanopore reads (read chemistries >= r10.4) using [Hifiasm](https://github.com/chhylp123/hifiasm). It takes either BAM files or FASTQ files from sequencing as input and will output a final primary assembly plus two haplotype assemblies and calculate basic assembly QC metrics from QUAST, BUSCO completeness using compleasm and estimate completeness and accuracy with kmers using Merqury.  

## Getting the pipeline  
Simply clone this repository from Github, after making sure git is installed on your machine! (Note: if you are using the Harvard Canon computing cluster, git is installed by default):  

`git clone https://github.com/harvardinformatics/pacbio_hifi_assembly.git`  

Then enter the directory: `cd pacbio_hifi_assembly/`  

You will also need snakemake installed to run the pipeline. The easiest way to install snakemake is via Conda/Mamba (preferably Mamba), instructions for which can be found [here](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html). In addition, in order to use cluster integration, snakemake v8+ requires a separate [SLURM executor plugin](https://anaconda.org/bioconda/snakemake-executor-plugin-slurm) to be installed. You can use conda to install this in the same conda environment that you installed snakemake in.

The snakemake SLURM plugin can now *perform automatic partition selection*, meaning it will automatically choose the correct queue based on the resources required for each job! We provide a partition config file for jobs on the Harvard Cannon cluster, which we specify using the `--slurm-partition-config` argument when running the pipeline (see below). For a more in-depth explanation, see our documentation [here](https://informatics.fas.harvard.edu/resources/snakemake-cannon-config/).


## Configuring the pipeline  
While partitons can be selected automatically, you will still need to configure the pipeline based on your input samples and required resources. 

### Configuring sample data
In the repo directory, there is a file in the `config/` subdirectory called `config.yaml` that you will need to modify to point towards your data. This configuration file contains a nested series of 'key:value' mappings (similar to a Python dictionary). 


#### Long read-only assembly
For a basic assembly using just PacBio Hifi or ONT reads, your configuration should look like this: 

```
samples:
  sampleA: 
    hifi: ["path/to/reads.bam"]
    readFileType: "bam"
  sampleB: 
    nanopore: ["path/to/reads.fastq.gz", "/path/to/reads2.fastq.gz"]
    readFileType: "fastq"
```

 Here, "sampleA" and "sampleB" are the **prefixes** for each sample and will be used to name the output assembly files, so change them to whatever you like. Each sample has two required arguments:

 - `hifi:` OR `nanopore:` followed by the path to the sequencing reads (enclosed in brackets and quotes, as shown above)
   -  If you have multiple read files for a single sample, separate the paths with **commas**
-  `readFileType:` which can eith be `"bam"` OR `"fastq"`, depending on your input data type
 
 You can have as many samples as you like, just add another tab-indented line with the sample name the required arguments. In the above example, this would create two assemblies, with `sampleA` using Hifi reads and `sampleB` using Nanopore reads (from two fastq files).

#### Optional: assemblies incorporating HiC reads
Hifiasm can use HiC reads as part of the assembly process to help properly **phase** the haplotype assemblies, which should result in few haplotype switch errors. If incorporating HiC reads for a given sample, add two more parameters (`hic1` and `hic2`) to that sample with the file paths to the paired HiC read files.

```
samples:
  sampleA: 
    hifi: ["path/to/reads.bam"]
    readFileType: "bam"
    hic1: ["path/to/hic_reads1.fastq"]
    hic2: ["path/to/hic_reads2.fastq"]
```

(Note this is NOT the same as scaffolding the assembly using HiC! To scaffold, use a program like [YaHS](https://github.com/c-zhou/yahs) on the assembly created by this pipeline)

#### Optional: assemblies incorporating Nanopore ultra-long reads
Hifiasm can use Nanopore ultra-long reads to scaffold contigs and improve assembly contiguity. Add the parameter `ultralong:` with the path to the FASTQ file containing the ultralong Nanopore reads:

```
samples:
  sampleA: 
    hifi: ["path/to/reads.bam"]
    readFileType: "bam"
    ultralong: ["path/to/ultralong_reads.fastq"] 
```

#### Optional: BUSCO QC
After performing the assembly the pipeline will do some quality control metrics, including using [compleasm](https://github.com/huangnengCSU/compleasm) to estimate BUSCO completeness, which requires setting the appropriate BUSCO lineage to test against. By default the pipeline will attempt to use the "eukaryota" lineage, but you will probably want to select it yourself in the `busco` section, e.g.:

```
busco:
  sampleA: "aves"
  sampleB: "ciliophora"
```

The pipeline will attempt to download that BUSCO lineage dataset and use it for the appropriate sample.

### Configuring resources
This workflow uses a workflow-specific profile that configures the resources given to each step of the pipeline. Resources needed will depend on the size and complexity of the genome, though the step that will be the most variable between users is likely only the actual `hifiasm` assembly step, and other steps won't require much tweaking of resources.

Resources are defined in the `profile/slurm/config.yaml` file. The only line you need to change is the `slurm_account` line, where you should set it to your Cannon cluster account. If you are running into memory issues with the any given step, you can increase the amount of RAM allocated by changing the `mem_mb` line. 


## Running the pipeline  
From the main directory, make sure you are in the `workflow/` subdirectory, which contains the `Snakefile` that determines the order in which the pipeline runs. Before you run the pipeline for real, it can be useful to first do a "dry run" to make sure the pipeline is configured properly and all the files are accessible. 

(NOTE: if you created your own version of the `config/config.yaml` file, be sure to change the `--configfile` parameter to point towards the correct location of the YAML file)

`snakemake --dry-run --profile ../profiles/slurm --configfile ../config/config.yaml`

If this works, you should see a table summarizing number of jobs that will be submitted along with some text saying "This was a dry-run." If it worked, you are good to submit it to the cluster.

For running the assembly on the cluster, here is an example SLURM file to run from within the `workflow` directory. 

```
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
```  

This script will submit a "head" job that runs for the entire length of the pipeline and coordinates submission of each step of the pipeline as individual SLURM jobs. If successful, you should see a subdirectory `workflow/results/` that contains the finished assembly and QC stats!  