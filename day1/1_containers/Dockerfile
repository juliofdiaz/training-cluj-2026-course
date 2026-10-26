# A minimal, reproducible image for seqkit.
# Build:  docker build -t course/seqkit:2.13.0 .
# Run:    docker run --rm -v "$PWD":/data -w /data course/seqkit:2.13.0 seqkit stats reads/*.fastq.gz

# 1. Pin the base image to an exact tag (better still: a digest, see README)
FROM mambaorg/micromamba:2.9.0

# 2. Labels make the image self-describing
LABEL org.opencontainers.image.title="seqkit" \
      org.opencontainers.image.description="seqkit for the Reproducible Genomics course" \
      org.opencontainers.image.source="https://github.com/juliofdiaz/training-cluj-2026-course"

# 3. Pin the tool version AND the channels it comes from
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        seqkit=2.13.0 \
        procps-ng \
    && micromamba clean --all --yes

# 4. Make the conda environment active for non-interactive commands
#    (Nextflow runs `bash .command.run`, not an interactive shell)
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH=/opt/conda/bin:$PATH

# No ENTRYPOINT/CMD: Nextflow supplies the command
