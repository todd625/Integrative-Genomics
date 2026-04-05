# HCS 7004 — Integrative Genomics Final Project
**Course:** HCS 7004 Genome Analytics · Spring 2026  
**Organization:** [HCS7004-Sp26](https://github.com/HCS7004-Sp26)

---

## Biological scenario

A novel fungal pathogen isolate was recovered from infected plant tissue exhibiting
characteristic disease symptoms. To understand the molecular basis of virulence, four
sequencing experiments were performed on this isolate. Your team has been given the raw
sequencing reads and must perform all analyses from scratch.

**Your integrative question:**
> *Using genome assembly, structural annotation, differential gene expression, and chromatin
> accessibility data, identify the master regulatory gene controlling virulence in this
> isolate and propose a specific molecular biotechnology strategy to exploit it for
> disease management.*

---

## Data location on OSC

All raw sequencing data is stored on the Ohio Supercomputer Center (OSC).
**Data files must never be copied into this repository.**

```
/fs/scratch/PAS3260/Team_Project/
├── 01_assembly/
│   └── ont_reads_R10.fastq.gz          # ONT R10.4.1 genomic reads, ~60x
├── 02_annotation/
│   ├── direct_rna_mycelium_invitro.fastq.gz
│   ├── direct_rna_infection_early.fastq.gz
│   └── direct_rna_infection_late.fastq.gz
├── 03_rnaseq/
│   ├── rnaseq_wt_rep[1-3]_R[1-2].fastq.gz    # 6 files: wildtype
│   └── rnaseq_mut_rep[1-3]_R[1-2].fastq.gz   # 6 files: avirulent mutant
├── 04_atacseq/
│   └── atac_wt_rep[1-3]_R[1-2].fastq.gz      # 6 files: WT chromatin accessibility
└── Containers/                                 # Apptainer SIF files
```

Set a shell variable at the start of every session to avoid typing the full path:
```bash
export DATA=/fs/scratch/PAS3260/Team_Project
```

---

## Repository structure

```
.
├── modules/
│   ├── 01_assembly/        # SLURM scripts for Flye + BUSCO
│   ├── 02_annotation/      # SLURM scripts for minimap2 + Funannotate2
│   ├── 03_rnaseq/          # SLURM scripts for HISAT2, featureCounts, DESeq2
│   └── 04_atacseq/         # SLURM scripts for bowtie2, MACS3, IGV session
├── results/
│   ├── 01_assembly/        # Assembly stats, BUSCO reports (NOT genome FASTA)
│   ├── 02_annotation/      # Gene count summaries, functional annotation tables
│   ├── 03_rnaseq/          # DEG tables, volcano plots, PCA plots
│   └── 04_atacseq/         # Peak BED files, IGV screenshots
├── containers/
│   └── containers.md       # Container pull commands (SIF files stay on OSC)
├── docs/
│   └── GIT_WORKFLOW.md     # Team Git workflow guide ← read this first
└── README.md               # This file
```

---

## Modules and tools

| Module | Input | Key tools | Expected output |
|---|---|---|---|
| 01 Assembly | `ont_reads_R10.fastq.gz` | Flye, BUSCO | Assembled genome FASTA, assembly stats |
| 02 Annotation | Assembly + direct RNA-seq | minimap2, Funannotate2 | GFF3, protein FASTA, functional annotations |
| 03 RNA-seq DEG | `rnaseq_*` FASTQ files | HISAT2, featureCounts, DESeq2 | DEG table, volcano plot, heatmap |
| 04 ATAC-seq | `atac_wt_*` FASTQ files | bowtie2, samtools, MACS3 | Peak BED, IGV screenshot at candidate locus |

Detailed instructions for each module are in `modules/0X_<name>/README.md`.

---

## Team workflow

See [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md) for the full guide.  
The short version:

1. Each module has a dedicated branch: `module-01`, `module-02`, `module-03`, `module-04`
2. Each team member works on their assigned module branch
3. Push your SLURM scripts and result summaries — never raw data or SIF files
4. Open a Pull Request when your module is complete; at least one teammate reviews it
5. The `main` branch is merged into only when a module is fully reviewed

---

## What goes in Git — and what does not

| ✅ Commit this | ❌ Never commit this |
|---|---|
| SLURM `.sh` scripts | `.fastq.gz`, `.fasta`, `.bam`, `.sam` files |
| R/Python analysis scripts | Assembled genome FASTA (> 100 MB) |
| Result summaries (TSV, CSV) | Apptainer `.sif` container files |
| Figures (PNG, PDF) | Intermediate files > 50 MB |
| Markdown documentation | Your OSC password or API keys |

A `.gitignore` is pre-configured to block the most common large file types.

---

## Deliverables

Each team submits a single integrative report addressing the biological question above.
The report must include evidence from all four modules and conclude with a specific,
mechanistically justified biotechnology intervention proposal.

**Report due date:** see course schedule on Carmen.
