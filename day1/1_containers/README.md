# Docker exercises (S2)

**The instructions are in the Day 1 handbook, section 1.** This page has optional extras, for when you finish section 1 early or want more after the course. Nothing later depends on them.

Run everything from this folder; the course reads are in `~/course/data/reads/`:

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0
```

## Extra A: who owns the files a container writes? (≈5 min)

In section 1.1 you ran fastp with `-u $(id -u):$(id -g)`. Run it once without, with new report names:

```bash
cd ~/course/day1/1_containers
docker run --rm -v ~/course/data/reads:/data -v "$PWD":/work -w /work $IMG \
  fastp -i /data/SA01_R1.fastq.gz -I /data/SA01_R2.fastq.gz -o /tmp/r1.fq.gz -O /tmp/r2.fq.gz \
        -j SA01_root.fastp.json -h SA01_root.fastp.html
ls -l SA01_root.*
rm -f SA01_root.*
```

**You should see** `root root` as the owner. **Answer:** why is that a problem on a shared server? (`rm` works here because the folder is yours.)

**Then:** what does `--rm` do? Run `docker run $IMG fastp --version` without it, then `docker ps -a`: the stopped container is still there. `docker container prune -f` removes it.

## Extra B: run the image by its fingerprint (≈3 min)

Section 1.1 printed the image's digest. Copy the part after `@`, `sha256:…`, and run the same image by it:

```bash
cd ~/course/day1/1_containers
docker run --rm quay.io/biocontainers/fastp@sha256:<paste> fastp --version
```

**You should see** the same version as in section 1.1. A tag like `latest`, or even `1.4.0`, can be moved by whoever controls the registry; a digest cannot. That is why a paper's Methods should give both.

## Extra C: build your own image (≈15 min)

Read the [Dockerfile](Dockerfile) in this folder. **Answer before building:**
- What would change if it said `seqkit` instead of `seqkit=2.13.0`?
- Why does it install `procps-ng`? (Hint: Nextflow uses `ps` to measure each task.)

```bash
cd ~/course/day1/1_containers
docker build -t course/seqkit:2.13.0 .
docker run --rm -u $(id -u):$(id -g) -v ~/course/data/reads:/data -w /data \
  course/seqkit:2.13.0 seqkit stats -a -T SA0*_R1.fastq.gz
```

**You should see** a table with one row per read file. **Answer:** compare `sum_len` (total bases) for SA01 and SA07. What do you notice?

**Stretch:** instead of writing a Dockerfile, ask Seqera Containers (<https://seqera.io/containers/>) for an image with `seqkit=2.13.0`. Compare it with yours: which would you rather cite?

## Extra D (read only): the same image on an HPC cluster

Most clusters do not allow Docker. They run the *same* image with Apptainer (formerly Singularity):

```bash
apptainer exec docker://quay.io/biocontainers/fastp:1.4.0--h43da1c4_0 fastp --version
```

In Nextflow you switch with `-profile apptainer` instead of `-profile docker`. Nothing else changes.
