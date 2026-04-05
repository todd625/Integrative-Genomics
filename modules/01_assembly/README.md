# Module 01: Genome Assembly

## Overview
This module performs de novo genome assembly using Flye assembler for long-read data, followed by assembly quality assessment using BUSCO.

## Software Used
- **Flye**: De novo assembler for long-read sequencing data
- **BUSCO**: Benchmarking Universal Single-Copy Orthologs for assembly completeness

## SLURM Scripts
- `flye_assembly.slurm`: Main assembly script
- `busco_evaluation.slurm`: Assembly quality assessment

## Expected Outputs
Results will be saved to `results/01_assembly/`:
- Assembly statistics summary
- BUSCO completeness report
- Assembly graph visualization (if applicable)

**Note**: Large assembly files (FASTA) are stored on HPC storage, not in git.

## Usage
```bash
# Submit assembly job
sbatch flye_assembly.slurm

# Submit BUSCO evaluation
sbatch busco_evaluation.slurm
```

## Container Information
See `containers/containers.md` for required container pull commands.
