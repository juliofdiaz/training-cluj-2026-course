# Day 2 handbook: nf-core and the cloud

*Reproducible Genomics using Containers, Workflow Managers and Cloud Computing · Cluj-Napoca, October 2026*

## What we will do today

| Time | Session | By the end you will have |
|---|---|---|
| 09:00 | Recap | Yesterday, in four questions |
| 09:15 | S6 nf-core | A community pipeline set up for our isolates, and checked |
| 10:45 | S7 AWS | What AWS is, then your pipeline run on rented cloud machines |
| 13:30 | After lunch | Your cloud runs checked, and laptop versus cloud compared |
| 14:00 | S8 Capstone | A decision: which isolates can we trust? |
| 16:25 | Wrap-up | Cloud cleaned up, **your verdicts in the class spreadsheet** |

Coffee 10:30 and 15:00 · lunch 12:30–13:30. The long cloud runs happen over lunch, so nobody waits for them.

Two folders today: **`~/course/day2/1_nfcore/`** for the community pipeline (bacass), and **`~/course/day1/3_bactflow/`**, your own pipeline from yesterday, which you now run in the cloud. Every block of commands starts with the `cd` line for its folder: run it first. Same conventions as Day 1: **Answer:** goes in your notes file, `~/course/notes.md`. Stuck for 3 minutes? Raise your hand, and an instructor comes to you.

---

## 5. nf-core: a community pipeline (S6, 09:15–10:30)

*nf-core is a cookbook in which every recipe was tested in many kitchens before it was printed.*

### 5.1 Read a pipeline like a user (09:30, the instructor demonstrates)

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

### 5.2 Prepare bacass for our 8 isolates (09:40)

**What we're doing:** setting up a community pipeline for our 8 isolates, and checking the setup without running anything.

```bash
cd ~/course/day2/1_nfcore
awk -F, 'NR==1 {print "ID\tR1\tR2\tLongFastQ\tFast5\tGenomeSize"; next}
         {print $1"\t"$2"\t"$3"\tNA\tNA\t2.8m"}' ~/course/data/reads/samplesheet.csv > bacass_samplesheet.tsv

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

nextflow run nf-core/bacass -r 2.6.1 -profile docker -params-file params.yaml -preview
```

`-preview` checks everything and runs nothing. **Done when:** `-preview` finishes without an error. Now break it on purpose: in `params.yaml`, change `assembly_type: short` to `assembly_type: shortt`, run the preview again, read the error, and put it back.

**Answer:** what is the difference between a setting in `params.yaml` and a setting in a `-c` config file? Which one does `assembler: unicycler` belong in?

### 5.3 Explore a finished bacass run (10:05)

**What we're doing:** comparing a finished nf-core/bacass run with the pipeline you built yesterday. The instructors ran bacass on our 8 samples earlier. Download it into `results_bacass_demo/`:

```bash
cd ~/course/day2/1_nfcore
bash ~/course/data/get_data.sh bacass-demo
```

Download fails? Raise your hand: an instructor copies the run to your machine. Then open `results_bacass_demo/multiqc/multiqc_report.html` and `results_bacass_demo/pipeline_info/`, copy this table into your notes file and fill in the bacass column:

| | bactflow (yours) | nf-core/bacass |
|---|---|---|
| Processes in the run | 7 | |
| Assembler | Shovill (SPAdes) | |
| Annotation | none | |
| Species or contamination check | none | |
| Where tool versions are recorded | `software_versions.tsv` | |
| Parameter checking before the run | none | |

### 5.4 Stretch (optional): borrow an nf-core module

Work in a copy: your own pipeline in `~/course/day1/3_bactflow` runs in the cloud at 11:40 and must stay as it is.

```bash
mkdir -p ~/course/day2/1_nfcore/stretch && cd ~/course/day2/1_nfcore/stretch
cp -r ~/course/help/pipeline/. .       # a copy of the full pipeline
nextflow module search abricate
nextflow module install nf-core/abricate/run
ls modules/nf-core/abricate/run/
```

Compare it with your own ABRICATE. Where do its tool options come from? (Hint: `ext.args`.)

---

## 6. Run it in the cloud (S7, 10:45–12:30, and 13:30–14:00)

*Cloud computing is renting computers by the second, like renting extra kitchens for a wedding instead of building them.*

### 6.1 AWS in 40 minutes (10:45, the instructor presents and demonstrates)

**What we're doing:** learning what AWS is and which of its services a pipeline uses, before we use them. Nothing to type. Keep these words at hand:

| AWS word | Think of it as | In this course |
|---|---|---|
| Region | The city where the data centre is | eu-central-1, Frankfurt |
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

`COURSE_USER` is your own folder in the shared bucket. **Never** paste access keys into a file or a chat.

### 6.3 Read the cloud settings (11:40, the instructor demonstrates first)

**What we're doing:** checking that your pipeline has the cloud settings. Only the profile changes; the code does not.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
nextflow config -profile awsbatch | grep -E 'executor|queue|workDir|outputDir|region'
# "Unknown configuration profile: 'awsbatch'"? Your conf/awsbatch.config is missing.
# Copy the course config files (this replaces your nextflow.config):
# cp -r ~/course/help/pipeline/{nextflow.config,conf} .
```

**Answer:** which files in your pipeline did you have to change to run in the cloud?

### 6.4 Run bactflow on AWS Batch (11:48)

**What we're doing:** running yesterday's pipeline on 20 isolates in the cloud, changing only the profile.

**Answer before you press enter:** yesterday your machine needed how many minutes for 8 isolates? The cloud now runs **20** (SA01–SA20). Will it take longer, or about the same?

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

Look inside the cloud work folder, in a second terminal:

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
aws s3 ls $COURSE_BUCKET/work/$COURSE_USER/ | head
nextflow log last -f name,native_id,status,realtime
```

If the run stops or fails, fix the cause and run `bash run_aws.sh` again from the same folder. `-resume` reuses every finished task, so you don't pay for them twice.

### 6.5 Launch bacass in the cloud, then go to lunch (12:05)

**What we're doing:** starting the community pipeline in the cloud, so it runs while you eat.

Open a **second terminal** (VS Code: *Terminal → New Terminal*) and leave bactflow running in the first one. In the new terminal, copy and run this whole block:

```bash
cd ~/course/day2/1_nfcore
aws s3 cp $COURSE_BUCKET/data/bacass_samplesheet_s3.tsv .
cat > params_aws.yaml <<EOF
input:           bacass_samplesheet_s3.tsv
outdir:          $COURSE_BUCKET/results/${COURSE_USER:?}/bacass
assembly_type:   short
assembler:       unicycler
prokka_args:     "--fast"
skip_busco:      true
skip_kmerfinder: true
kraken2db:       $COURSE_BUCKET/databases/k2_standard_08gb.tar.gz
EOF
nextflow run nf-core/bacass -r 2.6.1 -profile docker -c ~/course/day1/3_bactflow/conf/awsbatch.config \
    -params-file params_aws.yaml -bg > bacass_aws.log
```

`-profile docker` means "use containers"; `-c …/conf/awsbatch.config` (your own pipeline's cloud settings) sends the tasks to AWS Batch; `-bg` runs it in the background on your course machine, so it keeps going when you close your laptop.

**Done when:** `tail ~/course/day2/1_nfcore/bacass_aws.log` shows lines with `Submitted process`. Check it before you leave for lunch.

### 6.6 After lunch: did your bacass run work? (13:30)

**What we're doing:** checking whether the lunch-time cloud run worked, and what to do if it didn't.

```bash
cd ~/course/day2/1_nfcore
tail -n 15 bacass_aws.log
```

**Finished?** Copy its MultiQC report, open `results_aws/bacass_multiqc/multiqc_report.html`, and look at the **Kraken2** section. Note anything odd: you need it in the capstone.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
aws s3 sync $COURSE_BUCKET/results/${COURSE_USER:?}/bacass/multiqc/ results_aws/bacass_multiqc/
```

**Still running?** Fine: go on to §6.7, and check again at 14:30.

**An error?** Run it again from the same folder, with `-resume` added. Only the unfinished tasks run:

```bash
cd ~/course/day2/1_nfcore
nextflow run nf-core/bacass -r 2.6.1 -profile docker -c ~/course/day1/3_bactflow/conf/awsbatch.config \
    -params-file params_aws.yaml -resume -bg > bacass_aws.log
```

Fails again? Use the finished run from §5.3, in `~/course/day2/1_nfcore/results_bacass_demo/`.

### 6.7 Compare laptop and cloud (13:40)

**What we're doing:** checking that the cloud gave the same answers as your course machine, and comparing how long each took.

```bash
cd ~/course/day1/3_bactflow                   # your pipeline, from yesterday
aws s3 sync $COURSE_BUCKET/results/${COURSE_USER:?}/ results_aws/
diff results/pipeline_info/software_versions.tsv results_aws/pipeline_info/software_versions.tsv && echo "identical"
nextflow log                       # DURATION column: wall-clock time of each run
```

In `nextflow log`, compare two rows: yesterday's last run (its COMMAND ends with `samplesheet.csv -resume`) and today's run with `-profile awsbatch`. **Done when:** the diff prints `identical`, and the table below is in your notes file.

Cloud run stopped or not finished (for example, you closed your laptop over lunch)? Run `bash run_aws.sh` again in this folder: finished tasks are reused.

**Answer**, in your notes file:

| | Yesterday, course machine | Today, AWS Batch |
|---|---|---|
| Isolates | 8 | 20 |
| Wall-clock time | | |
| Most CPUs one task got | 4 | |
| Tool versions | | identical? |

Why was the cloud run not 20 times faster, or 2.5 times slower?

---

## 7. Capstone: the ward cluster (S8, 14:00–16:25)

Work **alone**, on your own results. Everything is in `~/course/day2/2_capstone/`: read `brief.md`, then fill in **`report.md`** in the same folder.

```bash
cd ~/course/day2/2_capstone
ls results_aws/          # a shortcut to your cloud results in ~/course/day1/3_bactflow/results_aws/
```

| Time | What |
|---|---|
| 14:05 | Section A: the QC triage table |
| 15:00 | Coffee |
| 15:15 | Section B: typing and AMR |
| 15:30 | Section C: your reproducibility statement |
| 15:45 | Stop. In the class spreadsheet (**<RESULTS_SHEET_URL>**), fill in **Verdict** (PASS, WARN or FAIL) and a one-line **Reason** in your 8 rows. Then prepare your one-minute verdict. |
| 15:50 | One-minute verdicts, everyone, from your seat |

All paths in the brief are inside `results_aws/` (the shortcut above). **No `results_aws/`** (your cloud run failed)? Use your laptop results in `~/course/day1/3_bactflow/results/` (SA01–SA08) and the bacass run in `~/course/day2/1_nfcore/results_bacass_demo/`. Hints are at the end of the brief, always there: try for 15 minutes first. The extension is optional: only if you finish A–C early.

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

The course machines are switched off after the course. To keep your work, in VS Code right-click a folder → *Download*. The useful, small parts are `~/course/day2/2_capstone/report.md`, `~/course/notes.md`, `~/course/day1/3_bactflow/results_aws/` and the settings in `~/course/day2/1_nfcore/`; skip any `work/` folder.

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
