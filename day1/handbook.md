# Day 1 handbook: Containers and Nextflow

*Reproducible Genomics using Containers, Workflow Managers and Cloud Computing · Cluj-Napoca, October 2026*

## What we will do today

| Time | Session | By the end you will have |
|---|---|---|
| 09:00 | Welcome and setup check | A working course machine |
| 09:30 | S1 Why results drift | A list of what can go wrong in an analysis |
| 10:00 | S2 Containers for workflows | A tool running from a pinned container on the course data |
| 11:00 | S3 Nextflow fundamentals | Your first pipelines, and a look inside them |
| 13:30 | S4 Building bactflow I | A pipeline that cleans and assembles 8 genomes |
| 15:15 | S5 Building bactflow II | Typing, resistance genes, one QC report, tool versions recorded |
| 16:30 | Wrap-up | **Your results in the class spreadsheet** |

Coffee 10:45 and 15:00 · lunch 12:30–13:30.

**Today's five ideas.** Everything else is in *Further reading* (§7), for later.
1. **A container pins a tool:** same version, any computer.
2. **A process is one step:** what goes in, what comes out, the command, the container.
3. **A channel carries one item per sample:** `[meta, reads]`.
4. **The work folder and `-resume`:** Nextflow remembers what is already done.
5. **Config and profiles:** the same code runs in a different place (`-profile docker` here, `-profile apptainer` on a cluster).

**What you leave with:** a pipeline you built and ran yourself, your notes, and your results next to everyone else's in the class spreadsheet. Tomorrow you keep working in the same folder.

## How to use this handbook

- Grey boxes are commands. Type them, or copy them from this handbook (on your machine: `~/course/day1/handbook.md`; right-click → *Open Preview* to read it formatted). `~/course/START_HERE.md` shows what is in each folder.
- **Answer:** marks a question. Write short answers in your notes file, `~/course/notes.md` (one file for both days). They help you tomorrow and in the capstone.
- **Stuck?** Check the troubleshooting table at the end of this handbook. Still stuck after 3 minutes? Raise your hand: an instructor comes to you. In the morning, compare your file with the solution file; in the afternoon, copy the checkpoint named in the step. Debugging a typo is not today's goal.
- Every block of commands starts with a `cd` line. Run it first, even if you think you are already there.

---

## 0. Setup (09:10, 20 min)

**What we're doing:** connecting to your course machine and checking it has everything for the day.

Connect with the card you were given. In VS Code: install the *Remote - SSH* extension, choose *Remote-SSH: Connect to Host*, type `participant@<address>` and the password. Or, in a terminal: `ssh participant@<address>`. Then:

```bash
bash ~/course/tools/check_vm.sh
```

**Done when:** the last line says `Ready.` (`WARN` lines are fine). Each `FAIL` line prints its fix: try it, then raise your hand if it still fails.

> If the check says Nextflow is too old: `export NXF_VER=26.04.9`, add the same line to `~/.bashrc`, and run the check again.

---

## 1. Containers for workflows (S2, 10:12–10:32)

*A container is a tool packed with everything it needs, like a meal kit: same dish in any kitchen.*

### 1.1 Run a tool from a pinned container

**What we're doing:** running fastp without installing it, from a container whose version can never change.

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0
docker pull $IMG
docker run --rm $IMG fastp --version
```

Now on real data. The container sees only the folders you share with `-v`: the reads (as `/data`) and this folder (as `/work`), where the reports go:

```bash
cd ~/course/day1/1_containers
docker run --rm -u $(id -u):$(id -g) -v ~/course/data/reads:/data -v "$PWD":/work -w /work $IMG \
  fastp -i /data/SA01_R1.fastq.gz -I /data/SA01_R2.fastq.gz -o /tmp/r1.fq.gz -O /tmp/r2.fq.gz \
        -j SA01.fastp.json -h SA01.fastp.html
ls -l SA01.fastp.*
```

**Answer:** where did `/tmp/r1.fq.gz` go? (Hint: only folders shared with `-v` stay.)

### 1.2 Tags and digests

**What we're doing:** finding the image's fingerprint, the name you would put in a paper.

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0      # the same image as in 1.1
docker inspect --format '{{index .RepoDigests 0}}' $IMG
```

**Done when:** it prints a name ending in `@sha256:` and a long code.

**Answer:** what is the difference between `fastp:latest`, `fastp:1.4.0--h43da1c4_0` and `fastp@sha256:…`? Which would you put in a paper?

Finished early? See *Further reading* (§7): who owns the files a container writes, and building your own image.

---

## 2. Nextflow fundamentals (S3, 11:15–12:30)

*Nextflow is the head chef: you hand over the recipe, it tells each cook what to do and when, and it remembers what is already cooked.*

The files are in `~/course/day1/2_nextflow_basics/`. Open them in VS Code from there.

### 2.1 Your first pipeline

**What we're doing:** running a tiny pipeline, looking inside the folder where each task runs, and seeing `-resume` skip work that is already done.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 01_hello.nf                               # 1. three tasks run
ls -a work/4e/546307*/                                 # 2. use the hash printed in YOUR run
cat work/4e/546307*/.command.sh                        # 3. the exact command that ran
nextflow run 01_hello.nf -resume                       # 4. prints cached: 3
nextflow run 01_hello.nf --greeting 'Salut' -resume    # 5. all 3 run again
```

**Done when:** command 4 printed `cached: 3`, and command 5 ran all 3 tasks again.

**Answer:**
1. Why did changing the greeting make every task run again?
2. `-resume` has one dash and `--greeting` has two. What is the difference?

### 2.2 Channels: from a samplesheet to `[meta, reads]`

**What we're doing:** turning a samplesheet into one item per sample, `[meta, reads]`, the shape every step this afternoon (and every nf-core pipeline) uses.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 02_channels.nf --input ~/course/data/reads/samplesheet.csv
```

Open the file and do **TODOs 1 and 2**, running it again after each one:
1. TODO 1: add a `group` to `meta`. Then, in the `reads.view` line, print `${meta}` instead of `${meta.id}`, so you can see the group.
2. TODO 2: count the samples.

**Done when:** each line shows `[id:SA01, group:ward_A]` (and so on), and the count says 8. TODOs 3 and 4 are optional. Solution: `solutions/02_channels_solution.nf`.

**Answer:** what is inside `meta` for SA03, and what is inside `reads`?

### 2.3 A real tool in a container

**What we're doing:** writing our first real process: fastp, in its container, on two samples, then on all eight.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 03_first_process.nf -with-docker --input ~/course/data/reads/samplesheet_test.csv
```

Do **TODOs 1 and 2** in the file and run it again:
1. TODO 1: add the JSON report as a second output (`emit: json`), and change the last line to `FASTP.out.json.view()`.
2. TODO 2: replace `--thread 2` with `--thread ${task.cpus}`.

TODO 3 is running it on all 8 samples:

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 03_first_process.nf -with-docker --input ~/course/data/reads/samplesheet.csv
```

**Done when:** the last lines print 8 paths ending in `.fastp.json`. TODO 4 is optional. Solution: `solutions/03_first_process_solution.nf`.

**Answer:** with 8 samples, how many fastp tasks ran at the same time on your machine? Why that number?

---

## 3. Build bactflow I: reads to assemblies (S4, 13:40–15:00)

This afternoon you build **bactflow**: reads → fastp → Shovill (assembly) → typing and resistance genes → one QC report. You don't type it all: you start from working code, add the important parts yourself, and copy the rest.

### 3.1 Step 1: a working FASTP pipeline (13:40)

**What we're doing:** starting from a pipeline that already works, and reading it until we can explain every part: where the samples come in, what FASTP takes and gives, and where the results go.

```bash
cd ~/course/day1/3_bactflow                            # your pipeline's folder
cp -r ~/course/help/checkpoints/step1/. .
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv
ls results/qc/fastp/
```

**Done when:** `ls` shows reports for SA01 and SA02.

From now on, **always run from inside `~/course/day1/3_bactflow/`**. `-resume` looks for your work in the folder you launch from.

**Answer**, by reading `main.nf` and `nextflow.config`:
1. Which lines turn the samplesheet into `[meta, reads]`? (You wrote the same thing this morning.)
2. What goes into FASTP, and what are its four outputs?
3. Which container does FASTP use, and where is that written?
4. What does `-profile docker` switch on? Find it in `nextflow.config`.

### 3.2 Step 2: connect SHOVILL yourself (14:00)

**What we're doing:** adding the assembly step. The SHOVILL process is already written; you connect it to FASTP and tell Nextflow where to save the assemblies.

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/checkpoints/step2_start/. .
```

Open `main.nf` and fill in the three TODO lines:
1. Run SHOVILL on FASTP's trimmed reads: `SHOVILL(FASTP.out.reads)`
2. Publish its contigs: `assemblies = SHOVILL.out.contigs`
3. Give them a folder, like `fastp` above it: `assemblies { path 'assemblies' }` (three lines)

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv -resume
grep -c '>' results/assemblies/*.fasta
```

**Done when:** `grep` prints a contig count for SA01 and SA02.

**Answer:** FASTP said `cached`. Why did it not run again?

Stuck? `cp -r ~/course/help/checkpoints/step2/. .` (inside `~/course/day1/3_bactflow`) is the finished step.

> **Course mode:** `params.shovill_args` in `nextflow.config` runs Shovill in a fast mode (2 k-mer sizes, no polishing). On our data it gives the same typing and resistance genes in a third of the time. For real projects, drop those options.

### 3.3 Launch all 8 samples (14:25)

**What we're doing:** running all 8 samples before the break, and seeing `-resume` reuse the 2 that are already done.

**Answer before you press enter:** how many FASTP and SHOVILL tasks will actually run?

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
```

**Done when:** FASTP and SHOVILL both end with `8 of 8, cached: 2`. It takes a few minutes: keep that terminal open until it finishes.

> **From now on, don't change the FASTP or SHOVILL code.** Changing it makes all 8 assemblies run again.

Finished early? Open `results/pipeline_info/timeline_*.html`: which task took longest?

---

## 4. Build bactflow II: typing and the full pipeline (S5, 15:15–16:30)

### 4.1 One step, one file (15:15, the instructor demonstrates)

**What we're doing:** watching. A process can live in its own file (a *module*) and be used with one `include` line. Tomorrow's nf-core pipeline is built entirely from modules.

### 4.2 Write the MLST step yourself (15:25)

**What we're doing:** adding a new analysis to your own pipeline, from a spec. Only the new step runs; all 8 assemblies are reused.

In your pipeline's folder, make a `modules` folder, then create the file `modules/mlst.nf` in it:

```bash
cd ~/course/day1/3_bactflow
mkdir -p modules
```

What goes in `modules/mlst.nf`:

| Part | Value |
|---|---|
| Process name, tag, label | `MLST`, `tag "${meta.id}"`, `label 'process_single'` |
| Container | `quay.io/biocontainers/mlst:2.35.0--hdfd78af_1` |
| Input | `tuple val(meta), path(fasta)` |
| Output | `tuple val(meta), path("${meta.id}.mlst.tsv"), emit: tsv` |
| Command | `mlst --label ${meta.id} --threads ${task.cpus} ${fasta} > ${meta.id}.mlst.tsv` |

Then two lines in `main.nf`: `include { MLST } from './modules/mlst'` at the top, and `MLST(SHOVILL.out.contigs)` in the `main:` block, after SHOVILL.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
```

**Done when:** MLST shows `8 of 8`, and FASTP and SHOVILL show `cached: 8`.

**Answer:** how long did the new step take, compared with the assemblies?

Stuck? Compare with `~/course/help/pipeline/modules/mlst.nf`.

### 4.3 Copy the full pipeline (15:50)

**What we're doing:** getting the finished bactflow (assembly QC, resistance genes, one QC report, tool versions) without typing it. Tomorrow you run exactly these files on 20 isolates.

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/pipeline/{main.nf,modules,assets,conf,nextflow.config} .
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
ls results/multiqc/
```

Only the new steps run (and MLST once more). **Done when:** `ls` shows `multiqc_report.html`. Then look at three small tables:

```bash
cat results/typing/mlst_summary.tsv
column -t results/amr/amr_summary.tsv
cat results/pipeline_info/software_versions.tsv
```

### 4.4 Look at the results (16:00)

**What we're doing:** checking whether a pipeline that "finished without errors" gave results we can trust.

In `~/course/day1/3_bactflow`, open `results/multiqc/multiqc_report.html` (VS Code: right-click → *Open with Live Preview*, or download it). Then read the two summary tables:

```bash
cd ~/course/day1/3_bactflow
cat results/typing/mlst_summary.tsv
column -t results/amr/amr_summary.tsv
```

**Answer:** are all 8 results trustworthy? Note anything odd in your notes file. (Don't fix it: tomorrow's capstone is about this.)

---

## 5. Add your results to the class spreadsheet (16:30, 10 min)

**What we're doing:** putting your 8 results next to everyone else's, so we can compare them tomorrow. No account needed.

```bash
cd ~/course/day1/3_bactflow
bash ~/course/tools/sheet_rows.sh "Your Name"
```

It prints 8 lines, one per isolate: your name, the sample, its sequence type (ST) and its resistance genes.

1. Select the 8 lines in the terminal and copy them.
2. Open the class spreadsheet: **<RESULTS_SHEET_URL>** (the link is also on the board).
3. Click the cell in column A of the first empty row, once, and paste. The four values go into four columns.

Leave other people's rows alone. Tomorrow, in the capstone, you add a verdict and a reason to each of your 8 rows.

### Self-check

- [ ] The sheet has 8 rows with your name
- [ ] Each row has an ST (or `none`) and its resistance genes, each in its own column

---

## 6. Optional: git in 15 minutes (after 17:00, or at home)

Not part of the course time, and nothing tomorrow depends on it. git keeps a history of your pipeline: a snapshot after each change, so you can see what changed and go back. It needs no account: everything stays on your machine.

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.org"   # any address: nothing is sent anywhere
cd ~/course/day1/3_bactflow
git init -b main                                   # start a history in this folder
cp ~/course/tools/gitignore .gitignore           # keep work/, results/ and reads out of it
git add .                                          # choose what goes into the snapshot
git commit -m "bactflow after Day 1"               # take the snapshot
git log --oneline                                  # list the snapshots
```

Now change something small: add a comment line above `MLST(SHOVILL.out.contigs)` in `main.nf`. Then:

```bash
git diff                                           # what changed since the last snapshot?
git commit -am "Explain the MLST step"             # snapshot every changed file git already knows
git log --oneline
git show HEAD~1:main.nf | head                     # main.nf as it was one snapshot ago
```

**Try:** delete a line of `main.nf` on purpose, then `git restore main.nf` brings it back.

Sharing your history with other people is what GitHub and GitLab are for. You don't need them for this course: see *Further reading*.

---

## 7. Further reading (after the course, or if you finish early)

We left these out of class time on purpose: they are useful, but not needed to build and run a pipeline today. Each one points to a course file that shows it (paths inside `~/course`), and to the official documentation.

| Topic | Where to see it in the course files | Official documentation |
|---|---|---|
| Who owns the files a container writes (`-u`) | `day1/1_containers/README.md`, exercise 2.1 | <https://docs.docker.com/engine/containers/run/> |
| Building your own container image | `day1/1_containers/Dockerfile` and its README | <https://docs.docker.com/build/> |
| More channel operators: `collect`, `join`, `groupTuple` | `day1/2_nextflow_basics/02_channels.nf`, TODOs 3–4; `help/pipeline/main.nf` | <https://www.nextflow.io/docs/latest/reference/operator.html> |
| Moving settings into a config file | `day1/2_nextflow_basics/04_config.nf` | <https://www.nextflow.io/docs/latest/config.html> |
| Labels, resource limits and retries | `help/pipeline/conf/base.config` | <https://www.nextflow.io/docs/latest/reference/process.html> |
| Where results are saved (`publish:` and `output {}`) | `help/pipeline/main.nf`, end of the file | <https://www.nextflow.io/docs/latest/workflow.html> |
| Recording tool versions automatically (`eval`, `topic`) | any file in `help/pipeline/modules/`, and `software_versions.tsv` | <https://www.nextflow.io/docs/latest/reference/channel.html> |
| Modules: one process per file, `include` | `help/pipeline/modules/` | <https://www.nextflow.io/docs/latest/module.html> |
| Steps that use all samples at once (QUAST, MultiQC) | `help/pipeline/main.nf`: the lines with `.collect()` | <https://www.nextflow.io/docs/latest/channel.html> |
| Run reports: timeline, trace, execution report | `results/pipeline_info/` after any run | <https://www.nextflow.io/docs/latest/reports.html> |
| Testing a pipeline | capstone extension E5 (`day2/2_capstone/extensions.md`) | <https://www.nf-test.com> |
| A full, free Nextflow course | – | <https://training.nextflow.io> (start with *Hello Nextflow*) |
| git, and sharing code on GitHub or GitLab | §6 above | <https://git-scm.com/book> (chapters 1–2) |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker not running, or you are not in the `docker` group | `bash ~/course/tools/check_vm.sh` prints the fix |
| `Nextflow version ... does not match` / `!>=26.04.0` | An older Nextflow is pinned | `export NXF_VER=26.04.9` |
| `No such file` for the samplesheet | You ran from the wrong folder | Run the `cd` line at the top of the step first. |
| A task failed | – | Open its work folder (printed in the error), then read `.command.err` and `.command.sh` |
| Output "missing" | The `output:` name doesn't match what the script wrote | `ls` the work folder and compare names |
| `-resume` re-runs everything | Different launch folder, or you edited the process code | Launch from `~/course/day1/3_bactflow/`. Compare your module with `~/course/help/pipeline/modules/`. |
| Shovill `exit 137` | Shovill asked for more memory than your machine has, so the system stopped it | Set `process_high` memory to `6.GB` in `conf/base.config` (so it fits), then run again with `-resume` |
| Pasted rows land in one cell of the spreadsheet | You double-clicked into the cell before pasting | Undo, click the cell once, and paste again |

## Glossary

| Word | Meaning | In the kitchen |
|---|---|---|
| **Container / image** | A tool packed with everything it needs / the frozen package it runs from | A meal kit |
| **Tag, digest** | A movable label / an unchangeable fingerprint of an image | "Pasta kit" versus the kit's barcode |
| **Pipeline (workflow)** | Steps and the data passed between them | A recipe |
| **Process** | One step, written once | One instruction in the recipe |
| **Task** | One run of a process, for one sample | One cook doing that instruction for one dish |
| **Channel** | The queue of values flowing between processes | The pass between stations |
| **Work directory** | The private folder where one task runs | A cook's station |
| **`-resume`** | Reuse tasks that already finished | "That dish is already cooked" |
| **Profile** | A named group of settings (`docker`, `apptainer`) | Which kitchen you cook in |
| **meta map** | Everything known about a sample, travelling with its files | The order ticket on the plate |
