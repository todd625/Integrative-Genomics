# Module 02: Genome Annotation

## Overview
This module performs genome annotation using minimap2 for evidence mapping and Funannotate2 for comprehensive gene prediction and functional annotation.

## Software Used
- **minimap2**: Fast sequence alignment for evidence mapping
- **Funannotate2**: Comprehensive eukaryotic genome annotation pipeline

## SLURM Scripts
- `minimap2_evidence.slurm`: Map evidence sequences to assembly
- `funannotate_predict.slurm`: Gene prediction pipeline
- `funannotate_annotate.slurm`: Functional annotation pipeline

## Expected Outputs
Results will be saved to `results/02_annotation/`:
- Gene count summaries
- Functional annotation tables
- GO term enrichment results
- Annotation quality metrics

## Usage
```bash
# Submit evidence mapping
sbatch minimap2_evidence.slurm

# Submit gene prediction
sbatch funannotate_predict.slurm

# Submit functional annotation
sbatch funannotate_annotate.slurm
```

## Container Information
See `containers/containers.md` for required container pull commands.
