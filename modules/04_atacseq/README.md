# Module 04: ATAC-seq Analysis

## Overview
This module performs ATAC-seq analysis using bowtie2 for read alignment, MACS3 for peak calling, and IGV for visualization.

## Software Used
- **bowtie2**: Fast and memory-efficient read alignment
- **MACS3**: Peak calling for ATAC-seq data
- **IGV**: Genome browser for visualization

## SLURM Scripts
- `bowtie2_alignment.slurm`: Align ATAC-seq reads
- `macs3_peakcalling.slurm`: Call accessible chromatin peaks
- `igv_visualization.slurm`: Generate IGV session files

## Expected Outputs
Results will be saved to `results/04_atacseq/`:
- Peak BED files
- IGV session files
- IGV screenshots of key regions
- Peak annotation summaries

## Usage
```bash
# Submit read alignment
sbatch bowtie2_alignment.slurm

# Submit peak calling
sbatch macs3_peakcalling.slurm

# Generate IGV visualization
sbatch igv_visualization.slurm
```

## Container Information
See `containers/containers.md` for required container pull commands.
