# Usage

Download example data:

```bash
bash scripts/bootstrap_example.sh
```

Run a local Docker test:

```bash
nextflow run . -profile test,docker
```

Override the reference FASTA:

```bash
nextflow run . -profile docker --fasta /path/to/reference.fa --input /path/to/samplesheet.csv --outdir results/custom
```

Inspect variant caller comparisons:

```bash
open results/test/variants/comparison/SAMPLE1_PE.variant_method_comparison.html
```

Resume after changing code:

```bash
nextflow run . -profile test,docker -resume
```

Clean generated work directories when you want to start over:

```bash
nextflow clean -f
```
