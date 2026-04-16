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


## Read alignment with hisat2
### build genome index (complete)
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
### trim the adapters off the fastqs, move into trimmed directory
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/06b_trimmomatic.sh << 'EOF'
#!/bin/bash
#SBATCH --account=PAS3260
#SBATCH --job-name=trimmomatic
#SBATCH --output=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/trimmomatic_%A_%a.out
#SBATCH --error=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/trimmomatic_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16G
#SBATCH --array=1-6

set -euo pipefail

CONTAINERS=/fs/scratch/PAS3260/Jonathan/Annotation/containers
TUTORIAL=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq
RAWDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq
TRIMDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/trimmed

SAMPLES=(rnaseq_wt_rep1 rnaseq_wt_rep2 rnaseq_wt_rep3 \
         rnaseq_mut_rep1 rnaseq_mut_rep2 rnaseq_mut_rep3)

SAMPLE=${SAMPLES[$((SLURM_ARRAY_TASK_ID - 1))]}

mkdir -p ${TRIMDIR}
mkdir -p ${TUTORIAL}/logs

echo "[$(date)] Trimming: ${SAMPLE}"

ADAPTER_PATH=/opt/conda/share/trimmomatic-0.40-0/adapters/TruSeq3-PE-2.fa

apptainer exec \
    --bind ${RAWDIR},${TRIMDIR},${TUTORIAL} \
    ${CONTAINERS}/trimmomatic_0.40.sif \
    trimmomatic PE \
        -phred33 -threads 8 \
        ${RAWDIR}/${SAMPLE}_R1.fastq.gz \
        ${RAWDIR}/${SAMPLE}_R2.fastq.gz \
        ${TRIMDIR}/${SAMPLE}_R1_trimmed.fastq.gz \
        ${TRIMDIR}/${SAMPLE}_R1_unpaired.fastq.gz \
        ${TRIMDIR}/${SAMPLE}_R2_trimmed.fastq.gz \
        ${TRIMDIR}/${SAMPLE}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${ADAPTER_PATH}:2:30:10:2:true \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:20 \
        MINLEN:36

echo "[$(date)] Done: ${SAMPLE}"
EOF

sbatch /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/06b_trimmomatic.sh

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
INDEX=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/novel_isolate_index
TRIMDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/trimmed
OUTDIR=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/aligned

SAMPLES=(rnaseq_wt_rep1 rnaseq_wt_rep2 rnaseq_wt_rep3 \
          rnaseq_gh31del_rep1 rnaseq_gh31del_rep2 rnaseq_gh31del_rep3)
SAMPLE=${SAMPLES[$((SLURM_ARRAY_TASK_ID - 1))]}

echo "[$(date)] Aligning: ${SAMPLE}"

apptainer exec --bind ${TUTORIAL},/fs/scratch/PAS3260/Jonathan ${HISAT2_SIF} \
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
| apptainer exec --bind ${TUTORIAL},/fs/scratch/PAS3260/Jonathan ${SAM_SIF} \
    samtools sort \
        -@ 8 \
        -m 1G \
        -o ${OUTDIR}/${SAMPLE}.sorted.bam -

apptainer exec --bind ${TUTORIAL},/fs/scratch/PAS3260/Jonathan ${SAM_SIF} \
    samtools index ${OUTDIR}/${SAMPLE}.sorted.bam

echo "[$(date)] Done: ${SAMPLE}"
echo "Alignment summary for ${SAMPLE}:"
cat /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/hisat2_${SAMPLE}.summary
EOF

sbatch /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/hisat2index/hisat2index.sh

## `featurecounts_quantify.slurm`: Count reads per gene - need to fix
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/06e_featurecounts.sh << 'EOF'
#!/bin/bash
#SBATCH --account=PAS3260
#SBATCH --job-name=featurecounts
#SBATCH --output=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/featurecounts_%j.out
#SBATCH --error=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/logs/featurecounts_%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16G

set -euo pipefail

CONTAINERS=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/containers
PELTASTER=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq

apptainer exec \
  --bind ${PELTASTER}:/data \
  ${CONTAINERS}/subread_2.0.6.sif \
  featureCounts \
    -a /data/00_data/genome/Pf_annotation.gff3 \
    -o /data/03_rnaseq/counts/Pf_SRR8119502_counts.txt \
    -t gene \
    -g ID \
    -p \
    --countReadPairs \
    -B \
    -C \
    -T 8 \
    /data/03_rnaseq/alignments/SRR8119502_sorted.bam

echo "=== featureCounts summary ==="
cat ${PELTASTER}/03_rnaseq/counts/Pf_SRR8119502_counts.txt.summary

echo ""
echo "=== First 15 data rows ==="
grep -v "^#" ${PELTASTER}/03_rnaseq/counts/Pf_SRR8119502_counts.txt \
  | head -15
EOF

sbatch ${PELTASTER}/scripts/06e_featurecounts.sh
