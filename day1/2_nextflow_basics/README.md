# Nextflow exercises (S3)

**The instructions are in the Day 1 handbook, §2.** This page only lists what is here, and one optional extra.

| File | Handbook | What you practise |
|---|---|---|
| `01_hello.nf` | §2.1 (11:15) | Running a pipeline, the `work/` folder, params, `-resume` |
| `02_channels.nf` | §2.2 (11:35) | A samplesheet → `[meta, [R1, R2]]`, `map`, `count` |
| `03_first_process.nf` | §2.3 (11:55) | A real tool (fastp) in a container, declaring outputs, `task.cpus` |
| `04_config.nf` + `04.config` | optional, below | Moving settings into a config file, profiles |
| `solutions/` | | The finished 02 and 03: read them when stuck, don't copy them |

In the `.nf` files, `TODO` marks the only lines you change.

## Optional extra: settings in a config file (`04_config.nf`)

For when you finish §2.3 early. Nothing later depends on it.

**1. Read `04_config.nf`.** The FASTP process has no `container` and no `cpus` line. Where do they come from? Open `04.config` to find out.

**2. Run it with that config file:**

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 04_config.nf -c 04.config -profile docker
```

You should see 2 FASTP tasks, and lines like `SA01: ran with 1 CPUs and 1 GB`.

**3. Add a second profile, `big`:**

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 04_config.nf -c 04.config -profile docker,big
```

You should see `SA01: ran with 4 CPUs and 4 GB`: the same code, different resources. This is how one pipeline runs on a laptop, a cluster and the cloud (tomorrow).

## Useful while you work

```bash
nextflow lint 02_channels.nf                      # checks the syntax without running it
nextflow log                                      # your previous runs in this folder
```
