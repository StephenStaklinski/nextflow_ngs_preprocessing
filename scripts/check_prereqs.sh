#!/usr/bin/env bash
set -euo pipefail

missing=0

check_command() {
    local cmd="$1"
    local help="$2"

    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "OK: ${cmd} ($(command -v "${cmd}"))"
    else
        echo "MISSING: ${cmd} - ${help}"
        missing=1
    fi
}

if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
    echo "OK: java ($(java -version 2>&1 | head -n 1))"
else
    echo "MISSING: java - Nextflow requires Java. Install Temurin/OpenJDK 17 or newer."
    missing=1
fi
check_command nextflow "Install from https://www.nextflow.io/docs/latest/install.html"

if command -v docker >/dev/null 2>&1; then
    echo "OK: docker ($(command -v docker))"
elif command -v apptainer >/dev/null 2>&1; then
    echo "OK: apptainer ($(command -v apptainer))"
elif command -v singularity >/dev/null 2>&1; then
    echo "OK: singularity ($(command -v singularity))"
else
    echo "MISSING: container runtime - install Docker Desktop, Apptainer, or Singularity."
    missing=1
fi

if [[ "${missing}" -ne 0 ]]; then
    echo
    echo "Install the missing prerequisites, then run:"
    echo "  bash scripts/bootstrap_example.sh --pull-containers"
    echo "  nextflow run . -profile test,docker"
    exit 1
fi

echo
echo "Prerequisites look ready."
