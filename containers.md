# Container Pull Commands

All Apptainer SIF files are stored on OSC at:
```
/fs/scratch/PAS3260/Team_Project/Containers/
```

**Do not re-pull containers unless instructed** — they are already available.
These commands are recorded here for reproducibility only.

## Module 01 — Assembly

```bash
# Flye — genome assembler (ONT HQ reads)
apptainer pull flye.sif \
    oras://community.wave.seqera.io/library/flye:2.9.5--b44a8f9bcf6c57f8

# BUSCO — genome completeness (Leotiomycetes lineage)
apptainer pull busco.sif \
    oras://community.wave.seqera.io/library/busco:5.8.3--pyhdfd78af_0
```

## Module 02 — Annotation

```bash
# minimap2 — long-read splice-aware aligner
apptainer pull minimap2.sif \
    oras://community.wave.seqera.io/library/minimap2:2.28--he4a0461_4

# SAMtools
apptainer pull samtools.sif \
    oras://community.wave.seqera.io/library/samtools:1.21--h50ea8bc_0

# Funannotate2 — structural and functional annotation
apptainer pull funannotate2.sif \
    oras://community.wave.seqera.io/library/funannotate2:2.0.2--pyhdfd78af_0
```

## Module 03 — Differential Expression

```bash
# HISAT2 — short-read splice-aware aligner
apptainer pull hisat2.sif \
    oras://community.wave.seqera.io/library/hisat2:2.2.1--hdbdd923_6

# Subread/featureCounts — read counting
apptainer pull subread.sif \
    oras://community.wave.seqera.io/library/subread:2.0.6--he4a0461_0

# R + DESeq2 — differential expression analysis
apptainer pull deseq2.sif \
    docker://quay.io/biocontainers/bioconductor-deseq2:1.42.0--r43hf9f3eb4_0
```

## Module 04 — ATAC-seq

```bash
# bowtie2 — short-read aligner
apptainer pull bowtie2.sif \
    oras://community.wave.seqera.io/library/bowtie2:2.5.4--he20e202_2

# SAMtools (shared with module 02)

# MACS3 — peak caller
apptainer pull macs3.sif \
    oras://community.wave.seqera.io/library/macs3:3.0.2--py312hf67a6ed_1

# deepTools — BAM QC and bigWig for IGV
apptainer pull deeptools.sif \
    oras://community.wave.seqera.io/library/deeptools:3.5.5--pyhdfd78af_0
```

## Binding scratch storage

Always include `--bind /fs/scratch:/fs/scratch` when running containers so they
can see your data on OSC:

```bash
CONTAINERS=/fs/scratch/PAS3260/Team_Project/Containers
apptainer exec --bind /fs/scratch:/fs/scratch \
    ${CONTAINERS}/hisat2.sif hisat2 -x genome_index -1 R1.fastq.gz -2 R2.fastq.gz -S out.sam
```
