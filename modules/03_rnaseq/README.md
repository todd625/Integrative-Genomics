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
```bash
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
```

### align rna seq reads with hisat2, pipe to samtools
```bash
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
```

## annotation?
```bash
apptainer exec prokka.sif \
prokka /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/prokka/novel_isolate_genome.fa \
  --outdir /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/prokka/output \
  --prefix isolate \
  --cpus 8
```

## `featurecounts_quantify.slurm`: Count reads per gene
```bash
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
STUFF=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq

apptainer exec \
  --bind ${STUFF}:/data \
  ${CONTAINERS}/subread_2.1.1.sif \
  featureCounts \
  -a /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/prokka/output/isolate.gff \
  -o /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/counts/counts.txt \
  -t CDS \
  -g ID \
  -p \
  --countReadPairs \
  -B \
  -C \
  -T 8 \
  /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/aligned/rnaseq_wt_rep1.sorted.bam \
  /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/aligned/rnaseq_wt_rep2.sorted.bam \
  /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/aligned/rnaseq_wt_rep3.sorted.bam

echo "=== featureCounts summary ==="
cat ${STUFF}/counts/counts.txt.summary

echo ""
echo "=== First 15 data rows ==="
grep -v "^#" ${STUFF}/counts/counts.txt \
  | head -15
EOF

sbatch /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/06e_featurecounts.sh
```

## differential gene expression (deseq2)
```bash

cat > /tmp/r_header.R << 'EOF'
# Set writable library path
lib_path <- "/fs/scratch/PAS3260/Fiona/R_libs"
dir.create(lib_path, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(lib_path, .libPaths()))

# Install missing packages
if (!requireNamespace("ggrepel", quietly = TRUE)) install.packages("ggrepel", lib = lib_path)
if (!requireNamespace("pheatmap", quietly = TRUE)) install.packages("pheatmap", lib = lib_path)
if (!requireNamespace("RColorBrewer", quietly = TRUE)) install.packages("RColorBrewer", lib = lib_path)
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager", lib = lib_path)
if (!requireNamespace("DESeq2", quietly = TRUE)) BiocManager::install("DESeq2", lib = lib_path)
EOF

# Prepend header to R script
cat /tmp/r_header.R /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2.R > /tmp/deseq2_full.R
cp /tmp/deseq2_full.R /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2.R

mkdir -p /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/deseq
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2.R << 'REOF'

suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(dplyr)
  library(tibble)
  library(ggrepel)
  library(pheatmap)
  library(RColorBrewer)
})

# count stuff

counts_file <- "/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/counts/counts.txt"

raw <- read.table(counts_file, header = TRUE, skip = 1, sep = "\t",
                  row.names = 1, check.names = FALSE)

# featureCounts columns 2-6 are metadata; counts start at column 6
# Column names unclean

count_mat <- raw[, 7:ncol(raw)]
colnames(count_mat) <- sub(".*/", "", colnames(count_mat))
colnames(count_mat) <- sub("\\.sorted\\.bam$", "", colnames(count_mat))

cat("Count matrix dimensions:", dim(count_mat), "\n")
cat("Sample names:", colnames(count_mat), "\n")
cat("Total read counts per sample:\n")
print(colSums(count_mat))

# sample metadata

sample_info <- data.frame(
  row.names = colnames(count_mat),
  condition = factor(c("WT", "WT", "WT",
                       "gh31del", "gh31del", "gh31del"),
                     levels = c("WT", "gh31del"))
)
cat("\nSample metadata:\n")
print(sample_info)

# make data set and prefilter

dds <- DESeqDataSetFromMatrix(
  countData = count_mat,
  colData   = sample_info,
  design    = ~ condition
)

# Remove genes with very low counts (< 10 total reads)

keep <- rowSums(counts(dds)) >= 10
dds  <- dds[keep, ]
cat("\nGenes after low-count filtering:", nrow(dds), "\n")

# run deseq
dds <- DESeq(dds)

# extract results
# (positive log2FC = higher in WT)

res <- results(dds,
               contrast = c("condition", "WT", "gh31del"),
               alpha = 0.05)

res_df <- as.data.frame(res) %>%
  tibble::rownames_to_column("gene_id") %>%
  arrange(padj)

cat("\nSummary of DESeq2 results:\n")
summary(res)

outdir <- "/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/deseq"

write.csv(res_df,
          file.path(outdir, "deseq2_results.csv"),
          row.names = FALSE)

# Significant DEGs: padj < 0.05 and |log2FC| >= 1
sig <- res_df %>%
  filter(!is.na(padj), padj < 0.05, abs(log2FoldChange) >= 1)

cat("\nSignificant DEGs (padj < 0.05, |log2FC| >= 1):", nrow(sig), "\n")
cat("Up in WT:", sum(sig$log2FoldChange > 0), "\n")
cat("Down in WT:", sum(sig$log2FoldChange < 0), "\n")
cat("\nTop 20 significant DEGs:\n")
print(head(sig, 20))

write.csv(sig,
          file.path(outdir, "sig_DEGs.csv"),
          row.names = FALSE)

# Variance-stabilizing transformation for visualization

vst_data <- vst(dds, blind = FALSE)

# PCA plot

pca_data <- plotPCA(vst_data, intgroup = "condition", returnData = TRUE)
pca_var  <- round(100 * attr(pca_data, "percentVar"), 1)

pca_plot <- ggplot(pca_data, aes(x = PC1, y = PC2, color = condition, label = name)) +
  geom_point(size = 4) +
  ggrepel::geom_text_repel(size = 3, max.overlaps = 20) +
  labs(title = "PCA of VST-normalized counts",
       subtitle = "P. fructicola WT vs gh31del",
       x = paste0("PC1: ", pca_var[1], "% variance"),
       y = paste0("PC2: ", pca_var[2], "% variance"),
       color = "Condition") +
  theme_bw(base_size = 12)

ggsave(file.path(outdir, "pca_plot.pdf"), pca_plot, width = 7, height = 5)

# 7. Volcano plot

res_df$significance <- "Not significant"
res_df$significance[res_df$padj < 0.05 & res_df$log2FoldChange >= 1]  <- "Up in WT"
res_df$significance[res_df$padj < 0.05 & res_df$log2FoldChange <= -1] <- "Down in WT"

# Highlight specific genes of interest

genes_of_interest <- c("t1.AMS68_008039",   # GH31 itself
                       "t1.AMS68_000995")   # check if it appears

volcano <- ggplot(res_df %>% filter(!is.na(padj)),
                  aes(x = log2FoldChange, y = -log10(padj),
                      color = significance)) +
  geom_point(alpha = 0.5, size = 1) +
  scale_color_manual(values = c("Not significant" = "grey60",
                                "Up in WT"        = "#D73027",
                                "Down in WT"      = "#4575B4")) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "black", linewidth = 0.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "black", linewidth = 0.5) +
  # Annotate top gene
  geom_point(data = res_df %>% filter(gene_id %in% genes_of_interest),
             size = 3, shape = 21, color = "black", fill = "gold") +
  ggrepel::geom_label_repel(
    data = res_df %>% filter(gene_id %in% genes_of_interest),
    aes(label = gene_id), size = 3, fill = "white", max.overlaps = 10) +
  labs(title = "Volcano Plot: WT vs gh31del",
       subtitle = "P. fructicola differential expression",
       x = expression(log[2]~"Fold Change (WT / gh31del)"),
       y = expression(-log[10]~"(adjusted p-value)"),
       color = "") +
  theme_bw(base_size = 12) +
  xlim(-6, 6)

ggsave(file.path(outdir, "volcano_plot.pdf"), volcano, width = 8, height = 6)

# 8. MA plot

pdf(file.path(outdir, "ma_plot.pdf"), width = 7, height = 5)
plotMA(res, main = "MA Plot: WT vs gh31del", alpha = 0.05, ylim = c(-6, 6))
dev.off()

# Sample distance heatmap

library(pheatmap)
sampleDists <- dist(t(assay(vst_data)))
sampleDistMatrix <- as.matrix(sampleDists)

pdf(file.path(outdir, "sample_distance_heatmap.pdf"), width = 6, height = 5)
pheatmap(sampleDistMatrix,
         clustering_distance_rows = sampleDists,
         clustering_distance_cols = sampleDists,
         main = "Sample-to-Sample Distances (VST)",
         color = colorRampPalette(rev(RColorBrewer::brewer.pal(9, "Blues")))(255))
dev.off()

cat("\nAll output files written to:", outdir, "\n")
cat("DESeq2 analysis complete.\n")
REOF
```
### submit job
cat > /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/run_deseq2.sh << 'EOF'
#!/bin/bash
#SBATCH --account=PAS3260
#SBATCH --job-name=deseq2
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2_%j.out
#SBATCH --error=/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2_%j.err

mkdir -p /fs/scratch/PAS3260/Fiona/R_libs

export APPTAINERENV_R_LIBS_USER=/fs/scratch/PAS3260/Fiona/R_libs

apptainer exec \
    --bind /fs/scratch/PAS3260/Fiona/R_libs:/fs/scratch/PAS3260/Fiona/R_libs \
    /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/containers/deseq2_1.40.2.sif \
    Rscript /fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/deseq2.R
EOF
/fs/scratch/PAS3260/Fiona/Team_Project/03_rnaseq/scripts/run_deseq2.sh
