# Capstone report: ____________ (your name)

## A. QC triage

Expected for *S. aureus*: genome ≈ 2.7–3.0 Mb, GC ≈ 32.5–33% (both reads and assembly). Real isolates should have ≥ 30×. The course data is 20× by design, so treat 15× as the minimum here.

Copy each Verdict and Reason into your rows of the class spreadsheet at 15:45.

| Isolate | Bases after QC | Est. depth (×) | Read GC % | Mean read length | # contigs (≥500 bp) | Total length | N50 | Kraken2 top species (%) | Verdict | Reason |
|---|---|---|---|---|---|---|---|---|---|---|
| SA01 | | | | | | | | | | |
| SA02 | | | | | | | | | | |
| SA03 | | | | | | | | | | |
| SA04 | | | | | | | | | | |
| SA05 | | | | | | | | | | |
| SA06 | | | | | | | | | | |
| SA07 | | | | | | | | | | |
| SA08 | | | | | | | | | | |

Thresholds you used, and why: …

## B. Typing and AMR (PASS isolates only)

| Isolate | ST | mecA | Other AMR genes (≥90% id, ≥80% cov) |
|---|---|---|---|
| | | | |

**Cluster assessment** (2–3 sentences, including what MLST *cannot* tell you and what analysis you would do next): …

## C. Reproducibility statement

```bash
# Exact commands used (copy from `nextflow log` / your shell history)

```

| Item | Value |
|---|---|
| bactflow version (the course's `pipeline/`, and the date you copied it) | |
| Nextflow version | |
| nf-core/bacass revision | |
| Container engine + profile | |
| AMR database + version/date | (from `software_versions.tsv`) |
| MLST scheme / tool version | |
| Input checksums | `~/course/data/reads/MD5SUMS` |
| Params (bacass `params.yaml`; bactflow options on the command line) | |

What would **still** be needed for someone in another lab to reproduce this exactly? …

## Extension (optional)

Which one, what you changed (diff or code), and evidence it worked: …

