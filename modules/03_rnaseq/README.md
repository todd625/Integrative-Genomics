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


## Read alignment with hisat2 need to finish
### build genome index
```bash
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/hisat2index.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=hisat2_index
#SBATCH --account=PAS3260
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/%x_%j.out
set -euo pipefail

echo "[$(date)] Building HISAT2 index..."

apptainer exec --bind /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq /fs/scratch/PAS3260/Jonathan/Annotation/containers/hisat2_2.2.2.sif \
    hisat2-build \
        -p 8 \
        /fs/scratch/PAS3260/Jonathan/Team_Project/01_novel_isolate/novel_isolate_genome.fa \
        /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/novel_isolate_index

echo "[$(date)] Index complete."
ls -lh /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/
EOF

sbatch /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/hisat2index.sh
```
### align rna seq reads with hisat2, pipe to samtools
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/hisat2index.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=hisat2_align
#SBATCH --account=PAS3260
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --array=1-6
#SBATCH --output=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/%x_%j.out

set -euo pipefail

TUTORIAL=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq
HISAT2_SIF=/fs/scratch/PAS3260/Jonathan/Annotation/containers/hisat2_2.2.2.sif
SAM_SIF=/fs/scratch/PAS3260/Jonathan/Peltaster/containers/samtools_1.23.1.sif
INDEX=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index
TRIMDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/trimmed
OUTDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/aligned

SAMPLES=(rnaseq_wt_rep1 rnaseq_wt_rep2 rnaseq_wt_rep3 \
          rnaseq_gh31del_rep1 rnaseq_gh31del_rep2 rnaseq_gh31del_rep3)
SAMPLE=${SAMPLES[$((SLURM_ARRAY_TASK_ID - 1))]}

echo "[$(date)] Aligning: ${SAMPLE}"

apptainer exec --bind ${TUTORIAL} ${HISAT2_SIF} \
    hisat2 \
        -p 8 \
        --dta \
        -x ${INDEX} \
        -1 ${TRIMDIR}/${SAMPLE}_R1_trimmed.fastq.gz \
        -2 ${TRIMDIR}/${SAMPLE}_R2_trimmed.fastq.gz \
        --rg-id ${SAMPLE} \
        --rg "SM:${SAMPLE}" \
        --rg "PL:ILLUMINA" \
        2>${TUTORIAL}/logs/hisat2_${SAMPLE}.summary \
| apptainer exec --bind ${TUTORIAL} ${SAM_SIF} \
    samtools sort \
        -@ 8 \
        -m 2G \
        -o ${OUTDIR}/${SAMPLE}.sorted.bam

# Index the sorted BAM
apptainer exec --bind ${TUTORIAL} ${SAM_SIF} \
    samtools index ${OUTDIR}/${SAMPLE}.sorted.bam

echo "[$(date)] Done: ${SAMPLE}"
echo "Alignment summary for ${SAMPLE}:"
cat /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/hisat2_${SAMPLE}.summary
EOF

sbatch /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/hisat2index.sh
