#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FASTQ_DIR="${ROOT_DIR}/data/fastq"
REFERENCE_DIR="${ROOT_DIR}/data/reference"
CONTAINER_DIR="${ROOT_DIR}/containers"

mkdir -p "${FASTQ_DIR}" "${REFERENCE_DIR}" "${CONTAINER_DIR}"

download() {
    local url="$1"
    local dest="$2"

    if [[ -s "${dest}" ]]; then
        echo "Already present: ${dest}"
        return
    fi

    echo "Downloading ${url}"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 -o "${dest}" "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${dest}" "${url}"
    else
        echo "ERROR: install curl or wget first." >&2
        exit 1
    fi
}

BASE_URL="https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon"
download "${BASE_URL}/sample1_R1.fastq.gz" "${FASTQ_DIR}/sample1_R1.fastq.gz"
download "${BASE_URL}/sample1_R2.fastq.gz" "${FASTQ_DIR}/sample1_R2.fastq.gz"
download "${BASE_URL}/sample2_R1.fastq.gz" "${FASTQ_DIR}/sample2_R1.fastq.gz"
download "${BASE_URL}/sample2_R2.fastq.gz" "${FASTQ_DIR}/sample2_R2.fastq.gz"

REFERENCE_URL="https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?id=MN908947.3&db=nuccore&report=fasta&retmode=text"
download "${REFERENCE_URL}" "${REFERENCE_DIR}/MN908947.3.fasta"

cat > "${ROOT_DIR}/data/samplesheet.csv" <<'EOF'
sample,fastq_1,fastq_2
SAMPLE1_PE,data/fastq/sample1_R1.fastq.gz,data/fastq/sample1_R2.fastq.gz
SAMPLE2_PE,data/fastq/sample2_R1.fastq.gz,data/fastq/sample2_R2.fastq.gz
EOF

IMAGES=(
    "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
    "quay.io/biocontainers/fastp:0.23.4--h125f33a_5"
    "quay.io/biocontainers/bwa:0.7.18--he4a0461_1"
    "quay.io/biocontainers/samtools:1.21--h50ea8bc_0"
    "quay.io/biocontainers/bcftools:1.21--h8b25389_0"
    "quay.io/biocontainers/multiqc:1.25--pyhdfd78af_0"
)

if [[ "${1:-}" == "--pull-containers" ]]; then
    if command -v docker >/dev/null 2>&1; then
        for image in "${IMAGES[@]}"; do
            echo "Pulling Docker image ${image}"
            docker pull "${image}"
        done
    elif command -v apptainer >/dev/null 2>&1; then
        for image in "${IMAGES[@]}"; do
            safe_name="$(echo "${image}" | tr '/:' '__').sif"
            echo "Pulling Apptainer image ${image}"
            apptainer pull "${CONTAINER_DIR}/${safe_name}" "docker://${image}"
        done
    elif command -v singularity >/dev/null 2>&1; then
        for image in "${IMAGES[@]}"; do
            safe_name="$(echo "${image}" | tr '/:' '__').sif"
            echo "Pulling Singularity image ${image}"
            singularity pull "${CONTAINER_DIR}/${safe_name}" "docker://${image}"
        done
    else
        echo "No Docker, Apptainer, or Singularity executable found. Skipping container pulls."
    fi
fi

echo
echo "Example data ready."
echo "Run with Docker:      nextflow run . -profile test,docker"
echo "Run with Apptainer:  nextflow run . -profile test,apptainer"
echo "Run with Singularity: nextflow run . -profile test,singularity"
