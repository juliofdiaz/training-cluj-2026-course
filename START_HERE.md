# Start here

Welcome! Everything for the two days is in this folder, `~/course`, on your own course machine.

## How to work

- **Open the handbook for the day** in VS Code (*File → Open File…*, or click it in the Explorer on the left):
  - Day 1: `day1/handbook.md`
  - Day 2: `day2/handbook.md`

  Every command you type is in the handbook, in order. To see it nicely formatted, right-click the file → *Open Preview*.
- **Each amber “Your turn” slide matches one handbook section.** Its footer names the section (for example *handbook section 2.2*), and its numbered steps are the handbook's bold steps, in the same words.
- **Open a terminal:** *Terminal → New Terminal*. Each step in the handbook starts with a `cd` line: run it first, so you are in the right folder.
- **Write your answers** in `notes.md` (in this folder). One file for both days.
- **Stuck?** Read the "Stuck?" box on the slide, then the troubleshooting table at the end of the handbook. Still stuck after 3 minutes? Raise your hand.

## What is where

| Folder | What it is | When |
|---|---|---|
| `day1/1_containers/` | Running a tool from a container | Day 1, 10:00 |
| `day1/2_nextflow_basics/` | Your first pipelines: `01_hello.nf`, `02_channels.nf`, `03_first_process.nf` (answers in `solutions/`) | Day 1, 11:00 |
| `day1/3_bactflow/` | **Your own pipeline.** You build it here on Day 1; on Day 2 you add an nf-core module to it and run it in the cloud. | Day 1 afternoon, Day 2 |
| `day2/1_nfcore/` | Checking a community pipeline, nf-core/bacass | Day 2, 09:30 |
| `day2/2_capstone/` | The capstone: `brief.md`, and `report.md`, which you fill in | Day 2, 14:00 |
| `data/reads/` | The course reads and samplesheets. Read them, don't change them. | Both days |
| `data/mash/` | The species database for Day 2's species check | Day 2 |
| `help/` | If you fall behind: `checkpoints/` (each step, finished) and `pipeline/` (the whole finished pipeline) | When you need it |
| `tools/` | `check_vm.sh` (is my machine ready?) and `sheet_rows.sh` (results for the class spreadsheet) | When the handbook says |

## First thing on Day 1

```bash
bash ~/course/tools/check_vm.sh
```

The last line should say `Ready.` (`WARN` lines are fine). A `FAIL` line prints its fix.
