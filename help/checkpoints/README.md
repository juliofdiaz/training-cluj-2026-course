# Checkpoints

If you fall behind in sections 3.1–3.2, copy the checkpoint for your section into your working folder and carry on. In sections 4.2–4.3, compare your files with `~/course/help/pipeline/modules/`; section 4.4 copies the finished pipeline for everyone.

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/checkpoints/step2/. .
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv -resume
```

Always launch from the same folder (`~/course/day1/3_bactflow/`). `-resume` looks for `work/` and `.nextflow/` in the folder you launch from.

| Checkpoint | Session / time | Contains |
|---|---|---|
| `step1/` | S4, 13:40 | Samplesheet → FASTP. Single file. Minimal config. Participants copy and read it (handbook section 3.1). |
| `step2_start/` | S4, 14:00 | Section 3.2's starting point: SHOVILL written but not connected; three TODO lines. |
| `step2/` | S4, ≈14:25 | + SHOVILL connected. Labels, resources, `docker` profile, reports. The section 3.2 answer. |
| `step3/` | (reference) | Refactored into `modules/`. + QUAST (cohort), MLST, ABRICATE. Reference only, not a class step. |
| `~/course/help/pipeline/` | S5, from 15:25 (compare `mlst.nf` in 4.2, copy `multiqc.nf` and `assets/` in 4.3, copy it all in 4.4) | + ABRICATE summary, MultiQC, `software_versions.tsv`, a `test` profile, and the settings used on Day 2 |
| `step4/` | Day 2, ≈10:20 | The full pipeline + the nf-core module MASH_SCREEN (species check) connected and configured. The Day 2 section 5.4 answer. |

Each checkpoint is self-contained and passes `nextflow lint`.
