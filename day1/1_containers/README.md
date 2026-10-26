# Docker exercises (S2)

Run everything from this folder:

```bash
cd ~/course/day1/1_containers
```

The course reads are in `~/course/data/reads/`.

## 2.1 Run a tool from a pinned BioContainer (≈7 min)

```bash
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0
docker pull $IMG
docker run --rm $IMG fastp --version
```

Now run it on real data. The container cannot see your files until you **mount** them:

```bash
docker run --rm \
  -u $(id -u):$(id -g) \
  -v ~/course/data/reads:/data \
  -v "$PWD":/work -w /work \
  $IMG \
  fastp -i /data/SA01_R1.fastq.gz -I /data/SA01_R2.fastq.gz \
        -o /tmp/r1.fq.gz -O /tmp/r2.fq.gz \
        -j SA01.fastp.json -h SA01.fastp.html
ls -l SA01.fastp.*
```

**Questions**
1. Run it again without `-u $(id -u):$(id -g)`, and name the reports `SA01_root.fastp.json` and `SA01_root.fastp.html` (new names: an overwritten file keeps its old owner). Who owns them (`ls -l SA01_root.*`)? Why is that a problem on a shared server? Remove them afterwards: `rm -f SA01_root.*` (you may delete them: the folder is yours)
2. Where did `/tmp/r1.fq.gz` go after the container exited?
3. What does `--rm` do? Run `docker ps -a` with and without it to see.

## 2.2 Tags are labels, digests are fingerprints (≈5 min)

```bash
docker inspect --format '{{index .RepoDigests 0}}' $IMG
```

Copy the `sha256:…` digest. Then run the same image **by digest**:

```bash
docker run --rm quay.io/biocontainers/fastp@sha256:<paste> fastp --version
```

**Discuss:** a tag such as `latest`, or even `1.4.0`, can be moved by whoever controls the registry. A digest cannot. When would you put the digest in a publication? (Answer: in the Methods or the supplementary software table, alongside the tag.)

## 2.3 Build your own image (≈15 min)

Read the [Dockerfile](Dockerfile) and answer these before building:
- What would change if you wrote `seqkit` instead of `seqkit=2.13.0`?
- Why is `procps-ng` installed? (Hint: Nextflow uses `ps` to collect task metrics.)

```bash
cd ~/course/day1/1_containers
docker build -t course/seqkit:2.13.0 .
docker run --rm -u $(id -u):$(id -g) -v ~/course/data/reads:/data -w /data \
  course/seqkit:2.13.0 seqkit stats -a -T SA0*_R1.fastq.gz
```

**Question:** write down `sum_len` (total bases) for SA01 and SA07 in `~/course/notes.md`. You need them tomorrow.

**Stretch:** instead of writing a Dockerfile, ask Seqera Containers (<https://seqera.io/containers/>) for an image with `seqkit=2.13.0`. Compare the image it gives you with yours. Which one would you rather cite?

## 2.4 (Read only) The same image on HPC

Most HPC clusters do not allow Docker. They run the *same* image with Apptainer/Singularity:

```bash
apptainer exec docker://quay.io/biocontainers/fastp:1.4.0--h43da1c4_0 fastp --version
```

In Nextflow you switch with `-profile apptainer` instead of `-profile docker`. Nothing else changes.
