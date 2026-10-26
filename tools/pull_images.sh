#!/usr/bin/env bash
# Pre-pull every image used in the course, so nobody waits on conference Wi-Fi.
set -uo pipefail
IMAGES=(
  quay.io/biocontainers/fastp:1.4.0--h43da1c4_0
  quay.io/biocontainers/shovill:1.4.2--hdfd78af_1
  quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2
  quay.io/biocontainers/mlst:2.35.0--hdfd78af_1
  quay.io/biocontainers/abricate:1.4.0--h05cac1d_0
  quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2
  quay.io/biocontainers/ncbi-amrfinderplus:4.2.7--hf69ffd2_0
  mambaorg/micromamba:2.9.0
)
for img in "${IMAGES[@]}"; do
  echo "pull $img"
  docker pull --quiet --platform linux/amd64 "$img" >/dev/null || echo "  !! failed: $img"
done
