# Reproducible Genomics: course material

The participant material for *Reproducible Genomics using Containers, Workflow Managers and Cloud Computing* (Cluj-Napoca, 29–30 October 2026): a two-day practical course on Docker, Nextflow, nf-core and the cloud for bacterial genomics.

On a course machine this folder is `~/course`. **Participants: open [START_HERE.md](START_HERE.md) first.** It explains how to work in pairs and what is where.

## The two days

- **Day 1 · Containers and Nextflow.** Run tools from pinned containers, learn Nextflow, then build your own pipeline, *bactflow*, on 8 *Staphylococcus aureus* isolates. Handbook: [day1/handbook.md](day1/handbook.md).
- **Day 2 · nf-core and the cloud.** Check the community pipeline nf-core/bacass, add a tested nf-core module to bactflow, run it on 20 isolates on AWS Batch, decide which isolates to trust, then add one more step of your choice. Handbook: [day2/handbook.md](day2/handbook.md).

## What is where

| Folder | What it holds |
|---|---|
| [day1/](day1/README.md) | Day 1 handbook and exercises; `3_bactflow/` is where you build your pipeline |
| [day2/](day2/README.md) | Day 2 handbook, the nf-core exercise and the capstone |
| [help/](help/README.md) | If you fall behind: each step finished, and the whole finished pipeline |
| [data/](data/README.md) | Scripts that fetch the course reads and the species database |
| [tools/](tools/README.md) | Check your machine, results for the class spreadsheet, updates |
| `notes.md` | Your answers, both days |

## Using it on your own computer

You need Java 17 to 26, Nextflow 26.04 or later, and Docker. Then:

```bash
git clone https://github.com/juliofdiaz/training-cluj-2026-course.git course
bash course/tools/check_vm.sh          # checks versions and resources, prints a fix for each problem
bash course/data/get_data.sh           # course reads (about 1 GB) and samplesheets
```

The handbooks assume the folder is at `~/course`. The finished pipeline is in [help/pipeline/](help/pipeline/README.md): `nextflow run main.nf -profile docker,test` runs it on 2 samples.

The pipeline is for learning, not production. For real analyses, consider nf-core/bacass.
