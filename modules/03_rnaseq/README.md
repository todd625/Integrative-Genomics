# Module 03: RNA-seq Analysis

## Overview
This module performs RNA-seq analysis using HISAT2 for read alignment, featureCounts for quantification, and DESeq2 for differential expression analysis.

## Software Used
- **HISAT2**: Fast and sensitive alignment program for RNA-seq reads
- **featureCounts**: Read counting program for genomic features
- **DESeq2**: Differential gene expression analysis

## SLURM Scripts
- `hisat2_alignment.slurm`: Read alignment to reference genome
- `featurecounts_quantify.slurm`: Count reads per gene
- `deseq2_analysis.slurm`: Differential expression analysis

## Expected Outputs
Results will be saved to `results/03_rnaseq/`:
- Differentially expressed gene (DEG) tables
- Volcano plots
- PCA plots
- Gene expression heatmaps

## Usage
```bash
# Submit read alignment
sbatch hisat2_alignment.slurm

# Submit read quantification
sbatch featurecounts_quantify.slurm

# Submit differential expression analysis
sbatch deseq2_analysis.slurm
```

## Container Information
See `containers/containers.md` for required container pull commands.
