# bactflow

A small, teachable Nextflow pipeline for bacterial isolate WGS (Illumina paired-end):
**fastp → Shovill → QUAST · mlst · ABRicate → MultiQC**, with automatic capture of tool versions.

It is the reference solution for the course *Reproducible Genomics using Containers, Workflow Managers and Cloud Computing*. It is meant for learning, not production. For production use, consider nf-core/bacass.

## Quick start

```bash
# 2-sample test on a course machine or laptop (Docker)
nextflow run main.nf -profile docker,test

# full cohort
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv

# AWS Batch (Day 2 handbook section 6)
nextflow run main.nf -profile awsbatch --input s3://<course-bucket>/data/samplesheet_s3.csv
```

Requires Nextflow ≥ 26.04 and Docker (or Apptainer/Singularity via `-profile apptainer`).

## Input

CSV with a header `sample,fastq_1,fastq_2`. Paths can be local, `s3://` or `https://`.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `--input` | – | Samplesheet (required) |
| `--outdir` | `results` | Output directory |
| `--genome_size` | `2.8M` | Expected genome size (Shovill uses it to subsample reads) |
| `--amr_db` | `ncbi` | ABRicate database (`ncbi`, `card`, `resfinder`, `argannot`, `vfdb`, …) |
| `--amr_minid` / `--amr_mincov` | `90` / `80` | ABRicate identity and coverage thresholds (%) |
| `--fastp_args` | `--detect_adapter_for_pe --length_required 50` | Extra fastp options |
| `--shovill_args` | `--minlen 200` | Extra Shovill options |
| `--save_trimmed` | `false` | Publish trimmed reads |

## Output

```
results/
├── qc/fastp/            per-sample fastp JSON + HTML
├── qc/quast/            QUAST report for all assemblies
├── assemblies/          <sample>.fasta + assemblies.csv (index)
├── typing/              mlst_summary.tsv
├── amr/                 amr_summary.tsv + per_sample/
├── multiqc/             multiqc_report.html
└── pipeline_info/       software_versions.tsv, trace, report, timeline, DAG
```

## Profiles

| Profile | Purpose |
|---|---|
| `docker` / `apptainer` / `singularity` | Container engine |
| `test` | 2 samples from `~/course/data/reads/samplesheet_test.csv` |
| `awsbatch` | AWS Batch executor, S3 work dir and results (env vars `COURSE_BUCKET`, `COURSE_USER`, `COURSE_QUEUE`, `AWS_REGION`) |

## Known limitations (by design: these are capstone discussion points)

- No species identification or contamination check: on Day 2 you add one, the nf-core module `mash/screen` (`~/course/help/checkpoints/step4/` has it).
- No automatic QC thresholds or flags (capstone extension E2).
- No annotation, no SNP-level relatedness analysis.
