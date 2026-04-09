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

# Business time!
## QC
```shell
cd /fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/
mkdir QC
apptainer exec /fs/scratch/PAS3260/Fiona/Peltaster/containers/fastqc_0.12.1.sif fastqc --threads 2 /fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/ont_reads_R10.fastq.gz --outdir=QC
```
### here i opened the html file in the browser to check things out! It looks like the quality score is around Q29ish. per sequence quality score peaks at 32ish. weird per base sequence content at beginning, im thinking adapters. gc distribution is super sharp- does this mean it was already filtered? mean gc content around 42. no Ns. overall i feel pretty okay about this.

## Preprocessing
### identify adapters
```shell
/fs/scratch/PAS3260/Fiona/Assembly/Software/bbmap/bbmerge.sh in1=/fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/ont_reads_R10.fastq.gz
in2=/fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/ont_reads_R10.fastq.gz outa=adapters_illumina.fa
```
### trim it up!
#### i used a filter length of 15 to accomadate the 10 base pair adapter shenanigan and give a bit of wiggle room initially, but the results weren't what i was hoping for so im going heavier duty (100)
/fs/scratch/PAS3260/Fiona/Assembly/Software/bbmap/bbduk.sh in=/fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/ont_reads_R10.fastq.gz out=/fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/Preprocessing/ont_reads_100bptrim.fastq.gz ftl=100 t=2

## assessment
apptainer exec /fs/scratch/PAS3260/Fiona/Assembly/Software/fastqc_multiqc.sif fastqc -t 2 /fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/Preprocessing/ont_reads_100bptrim.fastq.gz
/fs/scratch/PAS3260/Fiona/Team_Project/01_assembly/Preprocessing/ont_reads_100bptrim.fastq.gz --outdir=.
### looks pretty good i think?

## kmer analysis
mkdir kmeranalysis


## Assembly

## Assembly check
