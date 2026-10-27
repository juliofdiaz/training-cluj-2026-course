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

**Today's five ideas.** Everything else is in *Further reading* (section 7), for later.
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

**1. Find your name on the address list on the screen, and connect to that address.** The login details are on the screen too. In VS Code: install the *Remote - SSH* extension, choose *Remote-SSH: Connect to Host*, and type `<login>@<address>`. Or, in a terminal: `ssh <login>@<address>`.

**2. Run the machine check: `bash ~/course/tools/check_vm.sh`.**

**Why:** It confirms the tools, containers and reads are all there, so a problem shows up now, not in the middle of an exercise.

```bash
bash ~/course/tools/check_vm.sh
```

You should see one line per check, `[ OK ]` or `[WARN]`, and at the end `Ready.`

**3. A FAIL line? Try the fix it prints.** Then run the check again. Still failing? Raise your hand. If the check says Nextflow is too old: `export NXF_VER=26.04.9`, add the same line to `~/.bashrc`, and run the check again.

**Done when:** the last line says `Ready.` (`WARN` lines are fine).

---

## 1. Containers for workflows (S2, 10:12–10:32)

*A container is a tool packed with everything it needs, like a meal kit: same dish in any kitchen.*

### 1.1 Run a tool from a pinned container

**What we're doing:** running fastp without installing it, from a container whose version can never change, and finding the image's fingerprint: the name you would put in a paper.

**1. Pull fastp and print its version.**

**Why:** The container brings fastp with everything it needs: nothing is installed on your machine, and everyone runs the identical version.

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0
docker pull $IMG
docker run --rm $IMG fastp --version
```

You should see `fastp 1.4.0`.

**2. Run it on SA01: share the folders with `-v`.**

**Why:** A container sees nothing of your machine unless you share it. `-v` is how you hand it the reads and get the reports back: every pipeline task does exactly this.

The container sees only the folders you share with `-v`: the reads (as `/data`) and this folder (as `/work`), where the reports go.

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0      # the same image as in step 1
docker run --rm -u $(id -u):$(id -g) -v ~/course/data/reads:/data -v "$PWD":/work -w /work $IMG \
  fastp -i /data/SA01_R1.fastq.gz -I /data/SA01_R2.fastq.gz -o /tmp/r1.fq.gz -O /tmp/r2.fq.gz \
        -j SA01.fastp.json -h SA01.fastp.html
ls -l SA01.fastp.*
```

You should see `SA01.fastp.html` and `SA01.fastp.json`. **Answer:** where did `/tmp/r1.fq.gz` go? (Hint: only folders shared with `-v` stay.)

**3. Print the image’s fingerprint (digest) with `docker inspect`.**

**Why:** A tag can later be moved to a different image; a digest never changes. It is the name that lets someone else run exactly what you ran.

```bash
cd ~/course/day1/1_containers
IMG=quay.io/biocontainers/fastp:1.4.0--h43da1c4_0      # the same image as in step 1
docker inspect --format '{{index .RepoDigests 0}}' $IMG
```

You should see the image name, then `@sha256:` and a long code. **Answer:** what is the difference between `fastp:latest`, `fastp:1.4.0--h43da1c4_0` and `fastp@sha256:…`? Which would you put in a paper?

**Done when:** `ls` shows `SA01.fastp.html`, and `docker inspect` printed a name with `@sha256:`.

Finished early? Open `README.md` in `~/course/day1/1_containers/`: optional extras (who owns the files a container writes, building your own image).

---

## 2. Nextflow fundamentals (S3, 11:15–12:30)

*Nextflow is the head chef: you hand over the recipe, it tells each cook what to do and when, and it remembers what is already cooked.*

The files are in `~/course/day1/2_nextflow_basics/`. Open them in VS Code from there.

### 2.1 Your first pipeline

**What we're doing:** running a tiny pipeline, looking inside the folder where each task runs, and seeing `-resume` skip work that is already done.

**What the code does.** A Nextflow file has two kinds of blocks:
- **Processes.** Each one is a step, *defined* once, like a recipe card. A process on its own runs nothing.
- **The workflow.** The main body: the part that actually runs. It *calls* processes by name, like `SAY_HELLO(names)`, and decides which values go into them.

```
01_hello.nf
├── process SAY_HELLO { … }             ← defined here: the recipe for one step
└── workflow { … SAY_HELLO(names) … }   ← the main body: calls the process by name
```

Nextflow turns each value sent into a process into a **task**: 3 names, 3 tasks. Shortened, `01_hello.nf` says:

```
params.greeting = 'Hello'                                         ← a setting: change it with --greeting 'Salut'

process SAY_HELLO {                                               ← defined: one step, written once (runs nothing yet)
    input:  val name                                              ← what it needs: one name
    output: path "${name}.txt"                                    ← what it hands on: one file
    script: echo "${params.greeting}, ${name}! …" > ${name}.txt   ← the command, run once per name
}

workflow {                                                        ← the main body: what actually runs
    names = channel.of('Cluj', 'Napoca', 'Transilvania')          ← a channel: 3 values in a queue
    SAY_HELLO(names)                                              ← called: 3 values in, 3 tasks, each in its own folder
    SAY_HELLO.out.view { … }                                      ← print what came out
}
```

**1. Run `01_hello.nf`: three tasks run.**

**Why:** The smallest pipeline already has the parts every pipeline has: a process, a channel of inputs, and one task per input.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 01_hello.nf
```

You should see a line like `[4e/546307] SAY_HELLO (Napoca) | 3 of 3 ✔`, then three greetings. The code in brackets, `4e/546307`, is the start of one task's work folder.

**2. Look inside one task’s work folder: use the hash from your own run.**

**Why:** Every task runs in its own folder, with its exact command saved. When something fails, this is where you look.

Replace `4e/546307` with the code printed in your run:

```bash
cd ~/course/day1/2_nextflow_basics
ls -a work/4e/546307*/                                 # the task's files
cat work/4e/546307*/.command.sh                        # the exact command that ran
```

You should see files like `.command.sh`, `.command.log` and the task's `.txt` output, then the `echo` line that ran.

**3. Run it again with `-resume`: it prints `cached: 3`.**

**Why:** Nextflow remembers finished tasks, so after a crash or a change you only redo what is needed.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 01_hello.nf -resume
```

**4. Change the greeting: all 3 tasks run again.**

**Why:** Changing an input changes the task, so Nextflow runs it again: `-resume` reuses only what is truly the same.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 01_hello.nf --greeting 'Salut' -resume
```

**Done when:** step 3 printed `cached: 3`, and step 4 ran all 3 tasks again.

**Answer:**
- Why did changing the greeting make every task run again?
- `-resume` has one dash and `--greeting` has two. What is the difference?

### 2.2 Channels: from a samplesheet to `[meta, reads]`

**What we're doing:** turning a samplesheet into one item per sample, `[meta, reads]`, the shape every step this afternoon (and every nf-core pipeline) uses.

**What `meta` is.** A small map of `name: value` facts about one sample, which travels with that sample's files through the whole pipeline, like the order ticket that goes with each plate from the kitchen to the table. For SA01, at the end of this section, one item of the channel looks like this:

```
[ [id:SA01, group:ward_A],  [SA01_R1.fastq.gz, SA01_R2.fastq.gz] ]
  └─────── meta ────────┘   └───────────── reads ──────────────┘
```

The files change at every step (trimmed reads, then an assembly, then a typing result), but `meta` stays with them, so every step knows which sample it is working on: `${meta.id}` is how a step names its outputs, `SA01.fastp.json` for example.

**What the code does.** Step A reads the samplesheet; Step B turns each row into `[meta, reads]`:

```
samplesheet.csv                                        ← sample,fastq_1,fastq_2  (one line per sample)
   │  Step A: splitCsv(header: true)                   ← each line becomes a map, named by the header
   ▼
[sample:SA01, fastq_1:…/SA01_R1.fastq.gz, fastq_2:…]   ← the row: printed as 'row: …'
   │  Step B: map { row -> … }                         ← the row becomes [meta, reads]
   ▼
[[id:SA01], [SA01_R1.fastq.gz, SA01_R2.fastq.gz]]      ← one item per sample: what every step takes
```

Open `02_channels.nf` in VS Code and read it: its Steps A and B are written for you. You change it in one place, marked `TODO 1`, and run it again.

**1. Run `02_channels.nf` as it is.**

**Why:** You see the starting point: the samplesheet becomes one item per sample, but each item knows only the sample's name.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 02_channels.nf
```

You should see 8 `row:` lines (one per samplesheet row), then 8 lines like `SA01 -> [SA01_R1.fastq.gz, SA01_R2.fastq.gz]`. The order changes from run to run: that's normal.

**2. TODO 1: give each sample a group, print `${meta}`, run it again.**

**Why:** `meta` is where a pipeline keeps what it knows about each sample. Adding the ward there labels every sample without touching its files, and every later step receives the label too. (Tomorrow's capstone is about wards.)

SA01–SA04 come from `ward_A`, the others from `ward_B`. In Step B, replace the line `def meta = [id: row.sample]` with these two lines:

```groovy
def n = row.sample.replace('SA', '') as Integer
def meta = [id: row.sample, group: n <= 4 ? 'ward_A' : 'ward_B']
```

Then, in the `reads.view` line just below, change `${meta.id}` to `${meta}`, and run the same command again.
You should see: `[id:SA01, group:ward_A] -> [SA01_R1.fastq.gz, SA01_R2.fastq.gz]`, and so on for all 8.

**Done when:** each line shows its group, like `[id:SA01, group:ward_A]`. Stuck? Compare with `solutions/02_channels_solution.nf`: read it, don't copy it.

**Answer:** what is inside `meta` for SA03, and what is inside `reads`?

**Finished early? (optional)** Add each line on the empty lines under `// TODO 2, 3 and 4`, and run it again after each:
- **TODO 2:** count the samples: `reads.count().view { n -> "Number of samples: ${n}" }`. You should see `Number of samples: 8`.
- **TODO 3:** gather all sample IDs into one list: `reads.map { meta, _files -> meta.id }.collect().view()`. How many items does that channel emit?
- **TODO 4:** group the IDs by ward: `reads.map { meta, _files -> tuple(meta.group, meta.id) }.groupTuple().view()`.

### 2.3 A real tool in a container

**What we're doing:** writing our first real process: fastp, in its container, on two samples, then on all eight.

**What the code does.** The same two kinds of blocks as in section 2.1: the FASTP process is *defined* at the top and runs fastp on one sample, inside its container; the workflow at the bottom *calls* it with every sample. Shortened, `03_first_process.nf` says:

```
process FASTP {                                                    ← defined: one step, for one sample
    tag "${meta.id}"                                               ← the label on screen: FASTP (SA01)
    container 'quay.io/biocontainers/fastp:1.4.0…'                 ← the meal kit this step cooks with
    cpus 2                                                         ← the CPUs each task asks for
    input:  tuple val(meta), path(reads)                           ← one sample: its meta and its 2 read files
    output: tuple val(meta), path("…_trimmed_R{1,2}.fastq.gz")     ← what it hands on, meta still attached
    script: fastp --in1 … --out1 … --json SA01.fastp.json …        ← the command, as you would type it
}

workflow {                                                         ← the main body: what actually runs
    reads = channel.fromPath(params.input).splitCsv(…).map { … }   ← section 2.2: one [meta, reads] per sample
    FASTP(reads)                                                   ← called: one task per sample
    FASTP.out.reads.view()                                         ← print what came out
}
```

What goes in as SA01 comes out as SA01: `meta` travels through the process. A file the script writes but `output:` doesn't list stays behind in the work folder; that is TODO 1.

Open `03_first_process.nf` in VS Code and read it.

**1. Run `03_first_process.nf` as it is, on 2 samples.**

**Why:** A real tool, in its container, run once per sample by Nextflow: the pattern of every step you build this afternoon.

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 03_first_process.nf -with-docker
```

You should see 2 FASTP tasks (SA01 and SA02), then 2 lines listing each sample's trimmed reads.

**2. TODO 1: keep the JSON report as a second output.**

**Why:** Nextflow keeps, and passes on, only the files listed under `output:`. Declaring the report lets later steps use it: this afternoon the QC report collects these files.

fastp writes a report, `SA01.fastp.json`. Under `// TODO 1`, in the `output:` block, add:

```groovy
tuple val(meta), path("${meta.id}.fastp.json"), emit: json
```

Then change the last line of the file to `FASTP.out.json.view()`, and run the same command again.
You should see 2 lines, each with a path ending in `SA01.fastp.json` or `SA02.fastp.json`.

**3. TODO 2: use the CPUs Nextflow gives the task.**

**Why:** The number of CPUs then comes from the settings, not from the code: on a bigger machine you give the task more CPUs without editing the process.

In the `script:` block, replace `--thread 2` with `--thread ${task.cpus}`. Run it again: the same 2 lines.

**4. TODO 3: run it on all 8 samples.**

**Why:** The same code goes from 2 samples to 8 just by changing the samplesheet. Nextflow runs as many tasks at once as your CPUs allow.

The same pipeline, a different samplesheet:

```bash
cd ~/course/day1/2_nextflow_basics
nextflow run 03_first_process.nf -with-docker --input ~/course/data/reads/samplesheet.csv
```

**Done when:** the last lines print 8 paths ending in `.fastp.json`, one per sample. Stuck? Compare with `solutions/03_first_process_solution.nf`.

**Answer:** with 8 samples, how many fastp tasks ran at the same time on your machine? Why that number?

**Finished early? (optional)** TODO 4: run step 4's command again with `-resume` at the end. What changes, and why? Then the optional extra in `README.md`, in the same folder: settings moved into a config file.

---

## 3. Build bactflow I: reads to assemblies (S4, 13:40–15:00)

This afternoon you build **bactflow**: reads → fastp → Shovill (assembly) → typing and resistance genes → one QC report. You don't type it all: you start from working code, add the important parts yourself, and copy the rest.

### 3.1 A working FASTP pipeline (13:40)

**What we're doing:** starting from a pipeline that already works, and reading it until we can explain every part: where the samples come in, what FASTP takes and gives, and where the results go.

**What we've built so far.**

```
reads ─▶ FASTP   ← new: trimming and read QC, per sample
```

**What the code does.** The same pattern again: the FASTP process is defined at the top, and the workflow calls it. The workflow now has three parts: what runs, which results to keep, and where they go. Shortened, `main.nf` says:

```
process FASTP { … }                                   ← the same kind of step as in section 2.3

workflow {
    main:                                             ← what runs:
        ch_reads = channel.fromPath(params.input)…    ←   the samplesheet, one [meta, reads] per sample
        FASTP(ch_reads)                               ←   calls FASTP: one task per sample
    publish:                                          ← which results to keep:
        fastp = FASTP.out.json.join(FASTP.out.html)   ←   each sample's two reports, under the name fastp
}
output {                                              ← where kept results go, inside results/:
    fastp { path 'qc/fastp' }                         ←   results/qc/fastp/
}
```

`nextflow.config`, next to it, holds the settings (`params`) and the profiles, such as `-profile docker`.

**1. Copy the working FASTP pipeline into your folder.**

**Why:** You start from a pipeline that already works, so the afternoon is about understanding and extending it, not typing it.

```bash
cd ~/course/day1/3_bactflow                            # your pipeline's folder
cp -r ~/course/help/checkpoints/step1/. .
```

**2. Run it on the 2 test samples.**

**Why:** Two samples take a minute: always check a pipeline on a small test before running everything.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv
ls results/qc/fastp/
```

You should see a report for SA01 and one for SA02. From now on, **always run from inside `~/course/day1/3_bactflow/`**: `-resume` looks for your work in the folder you launch from.

**3. Answer the four questions by reading `main.nf` and `nextflow.config`:**

**Why:** These four parts (the input, a process, its container, a profile) are in every Nextflow pipeline, nf-core's included.
- Which lines turn the samplesheet into `[meta, reads]`? (You wrote the same thing this morning.)
- What goes into FASTP, and what are its four outputs?
- Which container does FASTP use, and where is that written?
- What does `-profile docker` switch on? Find it in `nextflow.config`.

**Done when:** `ls results/qc/fastp/` shows reports for SA01 and SA02, and you have four answers.

### 3.2 Connect SHOVILL yourself (14:00)

**What we're doing:** adding the assembly step. The SHOVILL process is already written; you connect it to FASTP and tell Nextflow where to save the assemblies.

**What we've built so far.**

```
reads ─▶ FASTP ─▶ SHOVILL   ← new: assembly, per sample
```

**What the code does.** SHOVILL is already written. Your three lines connect it to FASTP and keep its result:

```
FASTP ──trimmed reads──▶ SHOVILL ──contigs──▶ results/assemblies/

main:
    FASTP(ch_reads)
    SHOVILL(FASTP.out.reads)                                        ← TODO 1: call SHOVILL with FASTP's output
publish:
    assemblies = SHOVILL.out.contigs                                ← TODO 2: keep the contigs, named assemblies
output {
    assemblies { path 'assemblies' }                                ← TODO 3: … in results/assemblies/
```

**1. Copy the SHOVILL starting point into your folder.**

**Why:** The SHOVILL process is already written. What's missing is the wiring: the part that makes two steps a pipeline.

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/checkpoints/step2_start/. .
```

**2. Fill in the three TODO lines in `main.nf`:**

**Why:** TODO 1 sends FASTP's trimmed reads into SHOVILL: that one line is what joins two steps into a pipeline. TODOs 2 and 3 tell Nextflow which results to keep, and in which folder.
- TODO 1: run SHOVILL on FASTP's trimmed reads: `SHOVILL(FASTP.out.reads)`
- TODO 2: publish its contigs: `assemblies = SHOVILL.out.contigs`
- TODO 3: give them a folder, like `fastp` above it: `assemblies { path 'assemblies' }` (three lines)

**3. Run it on the test samples with `-resume`: FASTP is cached.**

**Why:** Only the new step runs: FASTP's results are reused, because nothing about FASTP changed.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv -resume
grep -c '>' results/assemblies/*.fasta
```

You should see FASTP `cached: 2`, SHOVILL `2 of 2`, then a contig count for SA01 and SA02.

**Done when:** `grep` prints a contig count for SA01 and SA02.

**Answer:** FASTP said `cached`. Why did it not run again?

Stuck? `cp -r ~/course/help/checkpoints/step2/. .` (inside `~/course/day1/3_bactflow`) is the finished step.

> **Course mode:** `params.shovill_args` in `nextflow.config` runs Shovill in a fast mode (2 k-mer sizes, no polishing). On our data it gives the same typing and resistance genes in a third of the time. For real projects, drop those options.

### 3.3 Launch all 8 samples (14:25)

**What we're doing:** running all 8 samples before the break, and seeing `-resume` reuse the 2 that are already done.

**1. Write down your prediction: how many FASTP and SHOVILL tasks will run?**

**Why:** Predicting first makes you reason about what `-resume` reuses; the run then tells you whether you were right.

**2. Launch all 8 samples with `-resume`.**

**Why:** SA01 and SA02 are already done, so only the 6 new samples run: the reuse you predicted.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
```

**3. Keep that terminal open until it finishes.** It takes a few minutes.

**Done when:** FASTP and SHOVILL both end with `8 of 8, cached: 2`.

**Answer:** was your prediction right? How many minutes did it take? (The `Duration` line at the end.) You compare it with the cloud tomorrow.

> **From now on, don't change the FASTP or SHOVILL code.** Changing it makes all 8 assemblies run again.

Finished early? Open `results/pipeline_info/timeline_*.html`: which task took longest?

---

## 4. Build bactflow II: typing and the full pipeline (S5, 15:15–16:30)

### 4.1 One step, one file (15:15, the instructor demonstrates)

**What we're doing:** watching. A process can live in its own file (a *module*) and be used with one `include` line. Tomorrow's nf-core pipeline is built entirely from modules.

### 4.2 Write the MLST step yourself (15:25)

**What we're doing:** adding a new analysis to your own pipeline, from a spec. Only the new step runs; all 8 assemblies are reused.

**What we've built so far.**

```
reads ─▶ FASTP ─▶ SHOVILL ─▶ MLST   ← new: typing, in its own module
```

**What the code does.** A process can be defined in its own file, a **module**: one recipe card per file. Until now FASTP and SHOVILL were written inside `main.nf`; MLST is the first process that lives in its own file. `main.nf` then needs one line to bring it in, one to call it, and two to keep its results:

```
modules/mlst.nf
    process MLST {                                                         ← defined: one step, in its own file
        input:  tuple val(meta), path(fasta)                               ← one assembly, with its meta
        output: tuple val(meta), path("${meta.id}.mlst.tsv"), emit: tsv    ← its typing result, named by sample
        script: mlst --label ${meta.id} … ${fasta} > ${meta.id}.mlst.tsv
    }

main.nf
    include { MLST } from './modules/mlst'                                 ← just above workflow {: bring the recipe card in
    main:    … MLST(SHOVILL.out.contigs)                                   ← called: each assembly goes into MLST
    publish: … mlst = MLST.out.tsv                                         ← keep its results, named mlst
    output { … mlst { path 'typing' } }                                    ← … in results/typing/
```

**1. Fill in the MLST skeleton from the spec: `modules/mlst.nf`.**

**Why:** One step per file (a *module*) keeps `main.nf` short, and a module can be reused in other pipelines. nf-core is built entirely this way.

Make a `modules` folder in your pipeline's folder, and open a new file in it:

```bash
cd ~/course/day1/3_bactflow
mkdir -p modules
code modules/mlst.nf
```

Paste this skeleton into the new file. Its name, tag and label are already filled in:

```groovy
process MLST {
    tag "${meta.id}"
    label 'process_single'
    container '___'

    input:
    ___

    output:
    ___

    script:
    """
    ___
    """
}
```

Then replace each `___` with its value from this table, and save:

| Blank | Value |
|---|---|
| `container` | `quay.io/biocontainers/mlst:2.35.0--hdfd78af_1` |
| `input:` | `tuple val(meta), path(fasta)` |
| `output:` | `tuple val(meta), path("${meta.id}.mlst.tsv"), emit: tsv` |
| `script:` (between the `"""`) | `mlst --label ${meta.id} --threads ${task.cpus} ${fasta} > ${meta.id}.mlst.tsv` |

The name in `input:` is the name the command uses: `path(fasta)` is what makes `${fasta}` work.

**2. Add two lines to `main.nf`: the `include`, and `MLST(SHOVILL.out.contigs)`.**

**Why:** The `include` makes the module available to your workflow; the call feeds it SHOVILL's assemblies, so MLST types each one.

`include { MLST } from './modules/mlst'` goes just above `workflow {`, below the two processes: it is your pipeline's first `include`. (Put it above FASTP and SHOVILL instead, and Nextflow sees them as new: all 8 assemblies would run again.) `MLST(SHOVILL.out.contigs)` goes in the `main:` block, after the SHOVILL line.

**3. Keep its results: two lines, in `publish:` and `output {}`.**

**Why:** As with SHOVILL's assemblies in section 3.2, a result is saved only if it is published and given a folder. Otherwise it stays hidden in `work/`.

In the `publish:` block, add `mlst = MLST.out.tsv`. In the `output {}` block, add a folder for it, like `assemblies` above it: `mlst { path 'typing' }` (three lines).

**4. Run all 8 samples with `-resume`.**

**Why:** Only MLST is new, so FASTP and SHOVILL are reused and the new step takes about a minute.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
cat results/typing/*.mlst.tsv
```

You should see MLST `8 of 8`, then one line per sample: its name, `saureus` and its sequence type (ST).

**Done when:** MLST shows `8 of 8`, FASTP and SHOVILL show `cached: 8`, and `cat` prints one line per sample.

**Answer:** how long did the new step take, compared with the assemblies?

Stuck? `fasta` is not defined: the `input:` line must say `path(fasta)`. Otherwise compare your module with `~/course/help/pipeline/modules/mlst.nf` (it has one extra output line, which records MLST's version). No `results/typing/`? Check that `publish:` and `output {}` both use the name `mlst`.

### 4.3 Collect all 8 reports into one: wire MultiQC (15:50)

**What we're doing:** adding a step that waits for all 8 samples and runs once: 8 fastp reports in, one QC report out.

**What we've built so far.**

```
reads ─▶ FASTP ─▶ SHOVILL ─▶ MLST                 ← per sample: 8 tasks each
           └─ 8 reports ─▶ .collect() ─▶ MULTIQC  ← new: all samples at once, 1 task
```

**What the code does.** Every step so far ran once per sample: 8 items in, 8 tasks. `.collect()` is the other kind of step: it waits until all 8 items have arrived and hands them on as **one** list, so the next step runs once, on everything.

```
SA01 SA02 … SA08 ──MLST(SHOVILL.out.contigs)──▶ 8 tasks              ← one per sample
SA01 SA02 … SA08 ──.collect()──▶ [SA01 … SA08] ──MULTIQC──▶ 1 task   ← one for all of them

FASTP.out.json                                                       ← 8 items: [meta, SA01.fastp.json], …
    .map { _meta, json -> json }                                     ← keep only the file: MultiQC needs the reports, not meta
    .collect()                                                       ← wait for all 8, then hand them on as one list
```

**1. Copy the MultiQC module and its settings file.**

**Why:** Like MLST, the step lives in its own file. It also needs a small settings file that says which columns the report shows.

```bash
cd ~/course/day1/3_bactflow
cp ~/course/help/pipeline/modules/multiqc.nf modules/
cp -r ~/course/help/pipeline/assets .
```

**2. Add the `include`, just above `workflow {`.**

**Why:** As in section 4.2, it makes the module available to your workflow. Placed below the MLST `include`, nothing you already ran looks new.

`include { MULTIQC } from './modules/multiqc'` goes on the line below `include { MLST } from './modules/mlst'`.

**3. Call it with all 8 reports at once: `.collect()`.**

**Why:** MLST needs one assembly at a time; MultiQC needs every report together, to put the 8 samples side by side. `.collect()` turns 8 items into one, so MultiQC runs once.

In the `main:` block, after the MLST line, add:

```groovy
MULTIQC(FASTP.out.json.map { _meta, json -> json }.collect(), file("${projectDir}/assets/multiqc_config.yml"))
```

The second input is the settings file you copied in step 1.

**4. Keep its report: two lines, in `publish:` and `output {}`.**

**Why:** As for SHOVILL and MLST: only published results reach `results/`.

In `publish:`, add `multiqc = MULTIQC.out.report`. In `output {}`, add `multiqc { path 'multiqc' }` (three lines, like `mlst`).

**5. Run all 8 samples with `-resume`.**

**Why:** Only the new step runs, and it runs once.

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
ls results/multiqc/
```

You should see FASTP, SHOVILL and MLST `cached: 8`, MULTIQC `1 of 1`, then `multiqc_report.html`.

**Done when:** MULTIQC shows `1 of 1`, and `ls results/multiqc/` shows `multiqc_report.html`.

**Answer:** MLST ran 8 times and MULTIQC once. Which part of your code made the difference?

Stuck? MULTIQC ran 8 times: the `.collect()` is missing. Anything else: section 4.4, step 1, copies the finished pipeline, MultiQC included.

### 4.4 Finish the pipeline and look at the results (16:05)

**What we're doing:** adding the last two steps, ready-made, then checking whether a pipeline that "finished without errors" gave results we can trust.

**What we've built so far.**

```
reads ─▶ FASTP ─▶ SHOVILL ─┬─▶ MLST ─────▶ results/typing/mlst_summary.tsv   ← you wrote it
           │               ├─▶ ABRICATE ─▶ results/amr/amr_summary.tsv       ← added for you: resistance genes
           │               └─▶ QUAST ────┐                                   ← added for you: assembly QC
           └─ 8 reports ─────────────────┴─▶ MULTIQC ─▶ results/multiqc/     ← you wrote it
every step ─▶ results/pipeline_info/software_versions.tsv                    ← each tool records its own version
```

QUAST and ABRICATE are two more steps of the kinds you just wrote: ABRICATE runs once per sample, like MLST; QUAST runs once over all samples, with `.collect()`, like MultiQC.

**1. Copy the finished pipeline and run it: QUAST and ABRICATE are added for you.**

**Why:** They follow the two patterns you have just written, so copying them saves typing, not learning. Everyone then has identical files for tomorrow, when you add one nf-core step and run them in the cloud.

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/pipeline/{main.nf,modules,assets,conf,nextflow.config} .
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
cat results/pipeline_info/software_versions.tsv
```

You should see FASTP and SHOVILL `cached: 8`; QUAST and ABRICATE run, and MLST and MULTIQC run once more (MultiQC now also reads QUAST's report). Then one line per tool with its version: nobody typed them, each step records its own.

**2. Open the MultiQC report.**

**Why:** "Finished without errors" doesn't mean "right". The QC report is where you check each sample's quality.

In `~/course/day1/3_bactflow`, open `results/multiqc/multiqc_report.html` (VS Code: right-click → *Open with Live Preview*, or download it).

**3. Read the two summary tables.**

```bash
cd ~/course/day1/3_bactflow
cat results/typing/mlst_summary.tsv
column -t results/amr/amr_summary.tsv
```

**4. Write in `~/course/notes.md`: are all 8 results trustworthy? Don’t fix anything.**

**Why:** Deciding what to trust is the real job. Tomorrow's capstone tests your decision with more evidence.

Note anything odd: tomorrow's capstone is about this.

**Done when:** both tables print, and your answer is in `~/course/notes.md`.

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
cd ~/course/day1/3_bactflow                        # your pipeline's folder
git init -b main                                   # start a history in this folder
cp ~/course/tools/gitignore .gitignore           # keep work/, results/ and reads out of it
git add .                                          # choose what goes into the snapshot
git commit -m "bactflow after Day 1"               # take the snapshot
git log --oneline                                  # list the snapshots
```

Now change something small: add a comment line above `MLST(SHOVILL.out.contigs)` in `main.nf`. Then:

```bash
cd ~/course/day1/3_bactflow
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
| Who owns the files a container writes (`-u`) | `day1/1_containers/README.md`, extra A | <https://docs.docker.com/engine/containers/run/> |
| Building your own container image | `day1/1_containers/README.md`, extra C, and the `Dockerfile` | <https://docs.docker.com/build/> |
| More channel operators: `collect`, `join`, `groupTuple` | handbook section 2.2, TODOs 3–4; `help/pipeline/main.nf` | <https://www.nextflow.io/docs/latest/reference/operator.html> |
| Moving settings into a config file | `day1/2_nextflow_basics/README.md`, the optional extra | <https://www.nextflow.io/docs/latest/config.html> |
| Labels, resource limits and retries | `help/pipeline/conf/base.config` | <https://www.nextflow.io/docs/latest/reference/process.html> |
| Where results are saved (`publish:` and `output {}`) | `help/pipeline/main.nf`, end of the file | <https://www.nextflow.io/docs/latest/workflow.html> |
| Recording tool versions automatically (`eval`, `topic`) | any file in `help/pipeline/modules/`, and `software_versions.tsv` | <https://www.nextflow.io/docs/latest/reference/channel.html> |
| Modules: one process per file, `include` | `help/pipeline/modules/` | <https://www.nextflow.io/docs/latest/module.html> |
| Steps that use all samples at once (QUAST, MultiQC) | section 4.3 (MultiQC); `help/pipeline/main.nf`, the QUAST line | <https://www.nextflow.io/docs/latest/channel.html> |
| Run reports: timeline, trace, execution report | `results/pipeline_info/` after any run | <https://www.nextflow.io/docs/latest/reports.html> |
| Testing a pipeline | capstone extension E5 (`day2/2_capstone/extensions.md`) | <https://www.nf-test.com> |
| A full, free Nextflow course | – | <https://training.nextflow.io> (start with *Hello Nextflow*) |
| git, and sharing code on GitHub or GitLab | Section 6 above | <https://git-scm.com/book> (chapters 1–2) |

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
| **meta map** (`meta`) | A small map of facts about one sample, like `[id:SA01, group:ward_A]`, that travels with its files through every step | The order ticket that goes with each plate |
