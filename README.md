# DNA FASTQ preprocessing training pipeline

This is a compact nf-core-style Nextflow DSL2 workflow for learning DNA sequencing read preprocessing. It runs quickly on tiny public paired-end FASTQ files and performs:

1. Raw read QC with FastQC
2. Adapter and quality trimming with fastp
3. Trimmed read QC with FastQC
4. Read alignment to a tiny SARS-CoV-2 reference with BWA-MEM
5. BAM sorting, indexing, and alignment QC with SAMtools
6. Basic haploid variant calling with bcftools and FreeBayes
7. Per-sample variant tables, HTML reports, and caller comparison reports
8. Run aggregation with MultiQC

It is intentionally much smaller than a full nf-core template so you can inspect every moving part during interview prep.

## Quick start

Prerequisites:

- Nextflow `>=25.10.0`
- Docker, Apptainer, or Singularity

Download the tiny example FASTQs and SARS-CoV-2 reference FASTA:

```bash
mkdir -p data/fastq data/reference

curl -fL -o data/fastq/sample1_R1.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R1.fastq.gz
curl -fL -o data/fastq/sample1_R2.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R2.fastq.gz
curl -fL -o data/fastq/sample2_R1.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R1.fastq.gz
curl -fL -o data/fastq/sample2_R2.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R2.fastq.gz

curl -fL -o data/reference/MN908947.3.fasta \
  'https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?id=MN908947.3&db=nuccore&report=fasta&retmode=text'
```

Run:

```bash
nextflow run . -profile test,docker
```

Use `-profile test,apptainer` or `-profile test,singularity` instead if that is your container engine.

## Inputs

The samplesheet is `data/samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
SAMPLE1_PE,data/fastq/sample1_R1.fastq.gz,data/fastq/sample1_R2.fastq.gz
```

`fastq_2` may be empty for single-end reads.

The example FASTQs in `data/fastq/` and reference FASTA in `data/reference/` are intentionally not committed to GitHub. Recreate them with:

```bash
mkdir -p data/fastq data/reference

curl -fL -o data/fastq/sample1_R1.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R1.fastq.gz
curl -fL -o data/fastq/sample1_R2.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R2.fastq.gz
curl -fL -o data/fastq/sample2_R1.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R1.fastq.gz
curl -fL -o data/fastq/sample2_R2.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R2.fastq.gz

curl -fL -o data/reference/MN908947.3.fasta \
  'https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?id=MN908947.3&db=nuccore&report=fasta&retmode=text'
```

## Outputs

Outputs are written under `results/test` when using `-profile test`:

- `fastqc/raw/`: FastQC reports before trimming
- `fastp/`: fastp HTML and JSON reports
- `trimmed/`: trimmed FASTQ files
- `fastqc/trimmed/`: FastQC reports after trimming
- `reference/`: BWA reference index files
- `alignment/sam/`: BWA-MEM SAM alignments
- `alignment/bam/`: sorted BAM and BAI files
- `alignment/qc/`: SAMtools flagstat alignment metrics
- `variants/vcf/bcftools/`: compressed bcftools VCFs and indexes
- `variants/vcf/freebayes/`: FreeBayes VCFs
- `variants/qc/`: bcftools stats files for MultiQC
- `variants/qc/freebayes/`: FreeBayes summary files for MultiQC
- `variants/tables/bcftools/`: per-sample bcftools variant TSV files
- `variants/tables/freebayes/`: per-sample FreeBayes variant TSV files
- `variants/reports/bcftools/`: small per-sample bcftools HTML variant summaries
- `variants/reports/freebayes/`: small per-sample FreeBayes HTML variant summaries
- `variants/comparison/`: per-sample TSV and HTML reports comparing calls shared by both methods and calls unique to each method
- `multiqc/`: `multiqc_report.html` with QC metrics, a FreeBayes variant QC table, and caller comparison tables
- `pipeline_info/`: Nextflow trace, timeline, report, and DAG

## Learning map

- `main.nf`: channel construction and workflow wiring
- `modules/local/*.nf`: individual process definitions
- `nextflow.config`: default parameters and execution profiles
- `conf/base.config`: process resources and containers
- `conf/test.config`: tiny test-data defaults

The structure borrows core nf-core conventions: DSL2 modules, `params.input`, centralized workflow outputs, process labels, containerized tools from BioContainers, test profile, `versions.yml` files, and MultiQC reporting.

## Note

This example was generated as a Nextflow refresher for learning the basic pipeline structure used in DNA sequencing read preprocessing workflows. It was generated with help from Codex.

The specific command-line options used for tools such as fastp, BWA-MEM, bcftools, and FreeBayes are intentionally simple for this tiny test dataset.
