# Day 2 handbook: nf-core and the cloud

*Reproducible Genomics using Containers, Workflow Managers and Cloud Computing · Cluj-Napoca, October 2026*

## What we will do today

| Time | Session | By the end you will have |
|---|---|---|
| 09:00 | Recap | Yesterday, in four questions |
| 09:15 | S6 nf-core | A community pipeline checked, and a tested nf-core module added to **your own** pipeline |
| 10:45 | S7 AWS | What AWS is, then your pipeline run on rented cloud machines |
| 13:30 | After lunch | Your cloud run checked, and laptop versus cloud compared |
| 14:00 | S8 Capstone | A decision: which isolates can we trust? |
| 16:25 | Wrap-up | Cloud cleaned up, **your verdicts in the class spreadsheet** |

Coffee 10:30 and 15:00 · lunch 12:30–13:30.

Three folders today: **`~/course/day2/1_nfcore/`** for the community pipeline (bacass, 09:30); **`~/course/day1/3_bactflow/`**, your own pipeline from yesterday, which gets a species check and then runs in the cloud; and **`~/course/day2/2_capstone/`** for the capstone (14:00). Every block of commands starts with the `cd` line for its folder: run it first. Same conventions as Day 1: **Answer:** goes in your notes file, `~/course/notes.md`. Stuck for 3 minutes? Raise your hand, and an instructor comes to you.

---

## 5. nf-core: use a community pipeline, then borrow one of its modules (S6, 09:15–10:30)

*nf-core is a cookbook in which every recipe was tested in many kitchens before it was printed. Today you use one whole recipe, then take one tested step and add it to your own.*

### 5.1 Read a pipeline like a user (09:25, the instructor demonstrates)

**What we're doing:** watching how to read a community pipeline's help and documentation. Nothing to type now: the commands are here for later.

```bash
cd ~/course/day2/1_nfcore
nextflow run nf-core/bacass -r 2.6.1 --help
nextflow run nf-core/bacass -r 2.6.1 --help assembler
```

Afterwards, on <https://nf-co.re/bacass/2.6.1>, **answer**:
1. What does bacass do, in one sentence?
2. Which parameters are required?
3. Why do we always add `-r 2.6.1`?

### 5.2 Prepare bacass for our 8 isolates (09:30)

**What we're doing:** setting up a community pipeline for our 8 isolates, and checking the setup without running anything. (Running it would take over half an hour: checking it is the skill.)

**1. Make bacass's samplesheet** from ours. bacass wants tabs and six columns:

```bash
cd ~/course/day2/1_nfcore
awk -F, 'NR==1 {print "ID\tR1\tR2\tLongFastQ\tFast5\tGenomeSize"; next}
         {print $1"\t"$2"\t"$3"\tNA\tNA\t2.8m"}' ~/course/data/reads/samplesheet.csv > bacass_samplesheet.tsv
head -3 bacass_samplesheet.tsv
```

You should see a header line, then one line per isolate starting with `SA01`.

**2. Write the settings file**, `params.yaml`. Copy the whole block: it writes the file for you.

```bash
cd ~/course/day2/1_nfcore
cat > params.yaml <<'EOF'
input:           bacass_samplesheet.tsv
outdir:          results_bacass
assembly_type:   short
assembler:       unicycler
prokka_args:     "--fast"
skip_busco:      true
skip_kmerfinder: true
skip_kraken2:    true
EOF
```

**3. Check it without running it.** `-preview` checks everything and runs nothing:

```bash
cd ~/course/day2/1_nfcore
nextflow run nf-core/bacass -r 2.6.1 -profile docker -params-file params.yaml -preview
```

**Done when:** `-preview` finishes without an error.

**4. Break it on purpose.** In `params.yaml`, change `assembly_type: short` to `assembly_type: shortt`. Run step 3's command again and read the error: it names the setting and the values it accepts. Then put `short` back.

**Answer:** what is the difference between a setting in `params.yaml` and a setting in a `-c` config file? Which one does `assembler: unicycler` belong in?

### 5.3 A tested step from nf-core (09:45, the instructor demonstrates)

**What we're doing:** watching. Your bactflow has no species check: if a sample is contaminated, nothing in it tells you. nf-core has a tested module for that, **MASH_SCREEN**. Mash compares your reads with about 90,000 reference genomes and lists the ones it finds in them. Nothing to type yet.

```bash
cd ~/course/day1/3_bactflow
nextflow module search mash            # nf-core's modules, from Nextflow's own module registry
```

### 5.4 Add the species check to your pipeline (09:55)

**What we're doing:** installing an nf-core module into the pipeline you built yesterday, connecting it, and running it. Only the new step runs; everything from yesterday is reused.

**1. Install it.** One command; it adds the folder `modules/nf-core/mash/screen/` and changes nothing else.

```bash
cd ~/course/day1/3_bactflow
nextflow module install nf-core/mash/screen
ls modules/nf-core/mash/screen/
```

**2. Read it.** Open `modules/nf-core/mash/screen/main.nf`. **Answer:** what are its two inputs? What does it output? Where do Mash's own options come from? (Hint: `task.ext.args`.)

**3. Connect it: four places in `main.nf`.**

| Where in `main.nf` | Add |
|---|---|
| At the top, with the other `include` lines | `include { MASH_SCREEN } from './modules/nf-core/mash/screen'` |
| In `main:`, after the `SHOVILL(...)` line | `MASH_SCREEN(FASTP.out.reads, channel.value([[id: 'refseq'], file(params.mash_db, checkIfExists: true)]))` |
| In `publish:`, with the other lines | `species = MASH_SCREEN.out.screen` |
| In `output { }`, like `mlst` | `species { path 'species' }` (three lines) |

The first input is your trimmed reads, `[meta, reads]`: the same shape you built yesterday. The second is the reference database, which the module also expects as `[meta, file]`.

**4. Configure it: two lines in `nextflow.config`.**

| Where in `nextflow.config` | Add |
|---|---|
| In `params { }` | `mash_db = "${projectDir}/../../data/mash/refseq.genomes.k21s1000.msh"` |
| At the very end: three lines | `process {`, then `withName: 'MASH_SCREEN' { ext.args = '-w -i 0.9' }`, then `}` |

`-w` keeps one best genome per group of near-identical genomes; `-i 0.9` hides weak matches. The module never hard-codes these: your config supplies them. Every nf-core module works this way.

**5. Run it on your 8 isolates.**

```bash
cd ~/course/day1/3_bactflow
nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
for s in SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08; do echo "== $s"; grep -vi phage results/species/$s.screen | sort -gr | head -3; done
```

**Done when:** MASH_SCREEN shows `8 of 8` while every other step says `cached`, and each isolate prints at least one line naming *Staphylococcus aureus*.

How to read a `.screen` file, one genome per line: **identity** (1 = identical), **shared** fingerprints (out of 1000), **median depth**, a p-value, then the genome's name. The loop hides lines naming a **phage**: those are normal, because *S. aureus* genomes carry phages.

**Answer:** does any of your 8 isolates list something other than *Staphylococcus*? Is any depth very different from the others? Write it down: you need it in the capstone.

Stuck? `cp -r ~/course/help/checkpoints/step4/. .` (inside `~/course/day1/3_bactflow`) is this step finished, module included: then run the step 5 command again. You may also meet the nf-core command-line tool's way of doing step 1, `nf-core modules install mash/screen`: the same module. We use Nextflow's own command, so there's nothing extra to install.

---

## 6. Run it in the cloud (S7, 10:45–12:30, and 13:30–14:00)

*Cloud computing is renting computers by the second, like renting extra kitchens for a wedding instead of building them.*

### 6.1 AWS in 40 minutes (10:45, the instructor presents and demonstrates)

**What we're doing:** learning what AWS is and which of its services a pipeline uses, before we use them. Nothing to type. Keep these words at hand:

| AWS word | Think of it as | In this course |
|---|---|---|
| Region | The city where the data centre is | eu-west-2, London |
| IAM | Keys and badges: who may open which door | Your course machine's role |
| S3 | A warehouse of labelled boxes | Reads, work folders, results |
| EC2 | Workbenches rented by the second | Batch rents them for you |
| Spot | Standby benches: cheaper, can be taken back | Our only queue |
| Batch | The foreman who rents benches when work arrives | Nextflow's `awsbatch` executor |
| CloudWatch | The logbook | Where task logs go |

**Answer:** in the console tour, where would you look for (a) your task's files, (b) its log, (c) the machine it ran on?

### 6.2 Check your access (11:25)

**What we're doing:** checking your course machine can use the course's AWS account. There is nothing to sign in to: the machine has a role that may use the course bucket and queue, and nothing else. Your four settings are already saved in `~/.course_env`.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
cat ~/.course_env                             # COURSE_USER, COURSE_BUCKET, COURSE_QUEUE, AWS_REGION
bash ~/course/tools/check_vm.sh --day2       # the last line should say Ready.
aws sts get-caller-identity                   # who AWS thinks you are
aws s3 ls $COURSE_BUCKET/data/reads/ --human-readable
```

**Done when:** the check's last line says `Ready.`, and `aws s3 ls` lists the reads.

`COURSE_USER` is your own folder in the shared bucket. **Never** paste access keys into a file or a chat.

### 6.3 Read the cloud settings (11:40, the instructor demonstrates first)

**What we're doing:** checking that your pipeline has the cloud settings. Only the profile changes; the code does not.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
nextflow config -profile awsbatch | grep -E 'executor|queue|workDir|outputDir|region'
```

**Done when:** the output shows `executor = 'awsbatch'` and a `workDir` ending in your course ID.

Stuck? `Unknown configuration profile: 'awsbatch'` means your `conf/awsbatch.config` is missing. Copy the course's config files (this replaces your `nextflow.config`, species check included), then run the `nextflow config` line again:

```bash
cd ~/course/day1/3_bactflow
cp -r ~/course/help/checkpoints/step4/{nextflow.config,conf} .
```

**Answer:** which files in your pipeline did you have to change to run in the cloud?

### 6.4 Run bactflow on AWS Batch (11:48)

**What we're doing:** running your pipeline, species check included, on 20 isolates in the cloud, changing only the profile.

**Answer before you press enter:** yesterday your machine needed how many minutes for 8 isolates (your answer from Day 1 §3.3)? The cloud now runs **20** (SA01–SA20). Will it take longer, or about the same?

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
cat > run_aws.sh <<'EOF'
#!/usr/bin/env bash
# Needs COURSE_BUCKET, COURSE_USER, COURSE_QUEUE, AWS_REGION in the environment (no names in this file)
: "${COURSE_USER:?not set: run  source ~/.course_env}" "${COURSE_BUCKET:?not set: run  source ~/.course_env}"
export NXF_VER=26.04.9
nextflow run main.nf -profile awsbatch --input $COURSE_BUCKET/data/samplesheet_s3.csv -resume
EOF
bash run_aws.sh
```

**Done when:** your terminal shows `awsbatch` and a FASTP line counting `of 20`. You don't need to wait for the end. **Leave this terminal running**: it is your run. If you need a terminal, open a new one (VS Code: *Terminal → New Terminal*).

While it runs, watch the instructor's screen: the jobs go `SUBMITTED → RUNNABLE → STARTING → RUNNING`, and machines appear in EC2 by themselves. **Answer:** why do the first jobs wait in `RUNNABLE`?

If the run stops or fails, fix the cause and run `bash run_aws.sh` again from the same folder. `-resume` reuses every finished task, so you don't pay for them twice.

### 6.5 While it runs: look inside the cloud (12:05)

**What we're doing:** finding where the cloud keeps your run: its work folders in S3, and each task's Batch job. In a **second terminal** (VS Code: *Terminal → New Terminal*), so the run keeps going in the first:

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
aws s3 ls $COURSE_BUCKET/work/$COURSE_USER/ | head        # one folder per task, now in S3
nextflow log | tail -1                                      # your run: STATUS is - while it goes
aws s3 ls $COURSE_BUCKET/results/$COURSE_USER/species/      # one .screen file per isolate, as they finish
```

**Done when:** you have seen your work folders in S3, and you know how many of your 20 isolates are screened. **Answer:** how many `.screen` files are in your cloud `species/` folder so far? The run is finished when there are 20.

(The instructor shows one of your jobs and its log in the console on the projector. `nextflow log last` with `-f` doesn't work while the run is going: the run keeps its records locked until it ends.)

**Before lunch:** if the run is still going, leave your laptop open, or simply run `bash run_aws.sh` again after lunch: `-resume` reuses every finished task.

### 6.6 After lunch: did your cloud run finish? (13:30)

**What we're doing:** checking that your cloud run finished, and restarting it if it didn't.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
nextflow log | tail -1                        # STATUS of your last run: OK, ERR, or - (not finished)
pgrep -f 'one.jar run'                        # prints a number while a run is still going
aws s3 ls $COURSE_BUCKET/results/$COURSE_USER/species/ | wc -l     # 20 when every isolate is screened
```

**OK and 20?** Go on to §6.7.

**`-` and `pgrep` prints a number?** Still running: go on to §6.7 and check again at 14:00.

**ERR, or `-` while `pgrep` prints nothing?** The run stopped (for example when your laptop closed). Run it again in the same folder: only the unfinished tasks run.

```bash
cd ~/course/day1/3_bactflow
bash run_aws.sh
```

Still failing at 13:40? Go on to §6.7 with what you have, and raise your hand. The capstone also works from your laptop results (§7).

### 6.7 Compare laptop and cloud (13:40)

**What we're doing:** checking that the cloud gave the same answers as your course machine, and comparing how long each took.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
aws s3 sync $COURSE_BUCKET/results/${COURSE_USER:?}/ results_aws/
diff results/pipeline_info/software_versions.tsv results_aws/pipeline_info/software_versions.tsv && echo "identical"
nextflow log                       # DURATION column: wall-clock time of each run
```

In `nextflow log`, compare two rows: yesterday's run from about 14:30 (see its TIMESTAMP; it assembled 6 of the 8, because SA01 and SA02 were already done) and today's run with `-profile awsbatch`. **Done when:** the diff prints `identical`, and the table below is in your notes file.

Cloud run still going? Do everything except the `diff` now, and run the `sync` and `diff` lines again at 14:00: `software_versions.tsv` is written when the run ends. Stopped (for example, you closed your laptop over lunch)? Run `bash run_aws.sh` again in this folder: finished tasks are reused.

Then look at the cloud's species check for the 8 course isolates:

```bash
cd ~/course/day1/3_bactflow
for s in SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08; do echo "== $s"; grep -vi phage results_aws/species/$s.screen | sort -gr | head -3; done
```

**Answer**, in your notes file:

| | Yesterday, course machine | Today, AWS Batch |
|---|---|---|
| Isolates | 8 | 20 |
| Wall-clock time | | |
| CPUs SHOVILL got (`nextflow log last -f name,cpus \| grep SHOVILL \| head -1`, once the run has ended) | 4 | |
| Tool versions | | identical? |

Why was the cloud run not 20 times faster, or 2.5 times slower?

---

## 7. Capstone: the ward cluster (S8, 14:00–16:25)

**What we're doing:** deciding, alone and with evidence, which of your 8 isolates can be trusted, and writing it down so others can repeat it.

**Everything for the capstone is in one file: `brief.md`.** It has the scenario, what to fill in and where the evidence is, the timings, and hints. You write your answers in `report.md`, in the same folder.

```bash
cd ~/course/day2/2_capstone
ls                       # brief.md, report.md, extensions.md, and results_aws (your cloud results)
```

Open `brief.md` in VS Code (right-click → *Open Preview*), and `report.md` next to it.

**Done when:** sections A to C of `report.md` are filled in, and at 15:45 your 8 rows in the class spreadsheet (**<RESULTS_SHEET_URL>**) have a **Verdict** and a **Reason**.

---

## 8. Wrap-up: clean up, and check your results (16:25, 22 min)

### 8.1 Clean up the cloud first

**What we're doing:** deleting your cloud folders, which keep costing money. Type these one at a time:

```bash
cd ~/course/day1/3_bactflow
echo ${COURSE_USER:?}                         # prints your course ID
pgrep -f 'one.jar run'                        # prints nothing = no run still going
aws s3 sync $COURSE_BUCKET/results/${COURSE_USER:?}/ results_aws/    # keep a copy
aws s3 rm $COURSE_BUCKET/work/${COURSE_USER:?}/ --recursive
aws s3 rm $COURSE_BUCKET/results/${COURSE_USER:?}/ --recursive
```

- `echo` gives an error (`COURSE_USER: parameter null or not set`)? Run `source ~/.course_env` and start again. `${COURSE_USER:?}` stops a command when your ID is missing, instead of deleting everyone's folder.
- `pgrep` prints a number? A run is still going: wait a few minutes and try again, or raise your hand.

**Done when:** `aws s3 ls $COURSE_BUCKET/work/` no longer lists your ID.

### 8.2 Check the class spreadsheet

Your 8 rows each have an ST, resistance genes, a **Verdict** and a **Reason**.

### 8.3 Optional: keep your work

The course machines are switched off after the course. To keep your work, in VS Code right-click a folder → *Download*. The useful, small parts are `~/course/day2/2_capstone/report.md`, `~/course/notes.md`, `~/course/day1/3_bactflow/results_aws/`, and `main.nf`, `nextflow.config` and `modules/` in `~/course/day1/3_bactflow/`; skip any `work/` folder.

### Final self-check

- [ ] `aws s3 ls $COURSE_BUCKET/work/` no longer lists your name
- [ ] `~/course/day2/2_capstone/report.md`: sections A–C filled in
- [ ] Your 8 rows in the class spreadsheet have a verdict and a reason

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Unable to locate credentials` | The course machine has lost its role | Tell an instructor |
| `AccessDenied` on S3 | Wrong bucket or prefix | `env \| grep COURSE` and compare with the board |
| Jobs stay `RUNNABLE` for more than 10 minutes | Machines still starting, or the queue is full | Wait 5 minutes, then tell an instructor |
| `CannotPullContainerError` | Image tag typo | Check the tag in the module |
| `exit status 137` on Batch | Out of memory | The pipeline retries with more memory automatically |
| bacass `-preview` complains about the samplesheet | Spaces instead of tabs | `cat -A bacass_samplesheet.tsv`: separators must show as `^I` |
| `No such file` for `refseq.genomes.k21s1000.msh` | The species database is not on your machine | `bash ~/course/data/get_data.sh mash`, or tell an instructor |
| `nextflow module install` fails | No access to the module registry | Copy the finished step instead: `cp -r ~/course/help/checkpoints/step4/. .` |
| MASH_SCREEN runs, but so does everything else | You changed FASTP or SHOVILL, launched from another folder, or ran something else in this folder since yesterday | `-resume` reuses the **last** run in this folder. Run `nextflow log`, copy the SESSION ID of yesterday's last run, and add it: `-resume <SESSION ID>` |
| Results "missing" after the AWS run | They are in S3 | `aws s3 ls $COURSE_BUCKET/results/$COURSE_USER/` |

## Glossary

| Word | Meaning | In the kitchen |
|---|---|---|
| **nf-core** | A community that builds and tests Nextflow pipelines | A cookbook tested by many kitchens |
| **Release (`-r 2.6.1`)** | A fixed, numbered version of a pipeline | The cookbook's edition |
| **Module** | One reusable process, shared between pipelines | A standard recipe card |
| **Region** | Where the data centre is | The city |
| **S3, bucket, prefix** | Object storage / a top-level store / the "folder" part of a path | A warehouse / one building / one shelf |
| **EC2, Batch** | Rented machines / the scheduler that starts them | Rented workbenches / the foreman |
| **Spot** | Spare machines at a discount that can be taken back | Standby tickets |
| **Data transfer out** (egress) | Downloading data from the cloud: it costs money | The delivery fee |
