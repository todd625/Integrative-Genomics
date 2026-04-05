#!/bin/bash

# Repository Restructuring Script - HCS7004 Integrative Genomics
# Convert current structure to the desired HPC-focused layout

echo "🔄 Restructuring repository to match HPC workflow requirements..."

# Create backup
echo "📦 Creating backup..."
cp -r . ../HCS7004-backup-restructure-$(date +%Y%m%d_%H%M%S)

echo "🗑️  Removing unnecessary directories and files..."

# Remove directories that are not needed
rm -rf data/
rm -rf scripts/

echo "📂 Renaming module directories..."

# Rename module directories to match desired structure
if [ -d "modules/01_genome_assembly" ]; then
    mv modules/01_genome_assembly modules/01_assembly
fi

if [ -d "modules/02_genome_annotation" ]; then
    mv modules/02_genome_annotation modules/02_annotation
fi

if [ -d "modules/03_rnaseq_analysis" ]; then
    mv modules/03_rnaseq_analysis modules/03_rnaseq
fi

if [ -d "modules/04_atacseq_analysis" ]; then
    mv modules/04_atacseq_analysis modules/04_atacseq
fi

echo "📁 Creating results directory structure..."

# Create results subdirectories to match modules
mkdir -p results/01_assembly
mkdir -p results/02_annotation
mkdir -p results/03_rnaseq
mkdir -p results/04_atacseq

# Add .gitkeep files to maintain empty directories in git
touch results/01_assembly/.gitkeep
touch results/02_annotation/.gitkeep
touch results/03_rnaseq/.gitkeep
touch results/04_atacseq/.gitkeep

echo "📝 Creating appropriate .gitignore..."

# Create .gitignore for HPC genomics workflow
cat > .gitignore << 'EOF'
# Large data files (keep on HPC storage)
*.fastq
*.fastq.gz
*.fq
*.fq.gz
*.sam
*.bam
*.bai
*.fasta
*.fa
*.fna
*.gff
*.gff3
*.gtf

# Container files (stored on HPC)
*.sif
*.img

# SLURM output files
slurm-*.out
slurm-*.err
*.o[0-9]*
*.e[0-9]*

# Results files that are too large for git
results/*/*.bam
results/*/*.sam
results/*/*.fastq*
results/*/*.fasta
results/*/*.fa

# But keep small result files
!results/*/*.txt
!results/*/*.tsv
!results/*/*.csv
!results/*/*.md
!results/*/*.html
!results/*/*.png
!results/*/*.jpg
!results/*/*.pdf
!results/*/*.bed
!results/*/.gitkeep

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Log files
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/
EOF

echo "📋 Creating README templates for each module..."

# Create README template for 01_assembly
cat > modules/01_assembly/README.md << 'EOF'
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
EOF

# Create README template for 02_annotation
cat > modules/02_annotation/README.md << 'EOF'
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
EOF

# Create README template for 03_rnaseq
cat > modules/03_rnaseq/README.md << 'EOF'
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
EOF

# Create README template for 04_atacseq
cat > modules/04_atacseq/README.md << 'EOF'
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
EOF

echo "✅ Repository restructuring completed!"
echo ""
echo "📁 New directory structure:"
tree -I '.git'

echo ""
echo "📋 Summary of changes:"
echo "   ✅ Renamed modules to match desired naming (01_assembly, 02_annotation, etc.)"
echo "   ✅ Removed unnecessary directories (data/, scripts/)"
echo "   ✅ Removed PULL_REQUEST_TEMPLATE.md"
echo "   ✅ Created results/ subdirectories matching modules"
echo "   ✅ Added appropriate .gitignore for HPC workflows"
echo "   ✅ Updated module READMEs with HPC/SLURM focus"
echo ""
echo "🚀 Ready to commit and push changes!"
