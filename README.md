### Snakemake workflow for the RNA-seq data of the Colorado potato beetle gene expression atlas
This workflow has been created to process the RNA-seq data of Colorado potato beetle gene expression atlas ([RJNA1067435](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1067435) 
published in [Wilhelm et al Sci Data 2025](https://www.nature.com/articles/s41597-025-04607-7)). This is not the original analysis described in
the paper, but a reanalysis based on an improved genome assembly and annotation (available on the 
[CPB Atlas 2 website](https://cpb-atlas2.uni-mainz.de/resources)). It was ran on Mogon, the HPC of the Johannes Gutenberg University, Mainz.

The parameters used in Fastp and Star are adjusted for this RNA-seq dataset and genome assembly, they should be changed to use the
pipeline on another dataset, assembly or species. You can run the workflow on an HPC with the following commands once Tmux and Conda are installed:
```
tmux new -s snakemake
conda env create -f environment.yaml
conda activate cpb-rnaseq
snakemake --executor slurm \
        --jobs 21 \
        --default-resources \
        slurm_account=<account name> \
        slurm_partition=<partition name>
```
