# Capstone extensions (pick one)

Ordered from easiest to hardest. All of them are realistic next steps for bactflow. Make the change in your own pipeline, in `~/course/day1/3_bactflow/`, and run it there with `-resume`.

## E1. Add a second AMR database (★, 10 min)

Run ABRICATE against **both** `ncbi` and `card` in the same run, without duplicating the process.

<details><summary>Hint</summary>

Make the database part of the input tuple, then use `combine` to pair every assembly with every database:

```nextflow
// modules/abricate.nf
input:
tuple val(meta), path(fasta), val(db)

// main.nf
ch_dbs = channel.of('ncbi', 'card')
ABRICATE(SHOVILL.out.contigs.combine(ch_dbs))   // [meta, fasta] x db -> [meta, fasta, db]
```
16 tasks instead of 8, and the output file names already include `${db}`.
</details>

Question: do the two databases agree for your PASS isolates?

## E2. Automatic QC flags (★★, 25 min)

Add a process `QC_FLAGS` that reads the QUAST `report.tsv` and writes `qc_flags.tsv` with PASS/WARN/FAIL per sample, using thresholds from params (`params.max_contigs`, `params.min_length`, `params.max_length`, `params.gc_range`). Use a small Python or awk script in the `script:` block, and the container `python:3.12-slim` (it lacks `ps`, so the trace will have no CPU/memory metrics for this task. Why does that matter when you size resources?).

Bonus: publish it, and add it to MultiQC as a custom-content table (`*_mqc.tsv`).

Question: would your flags have caught the isolates you failed by hand? Which threshold catches which?

## E3. A second nf-core module (★★, 20 min)

You added MASH_SCREEN this morning. Now replace your own ABRICATE with nf-core's: `nextflow module install nf-core/abricate/run`, connect it the same way, set its options with `ext.args` in `nextflow.config`, and compare `software_versions.tsv` before and after. Which ABRicate version are you running now?

## E4. Right-size the resources (★★, 20 min)

From your AWS trace, right-size SHOVILL and one other process in a custom config, `conf/rightsized.config`. Re-run on AWS with `-c conf/rightsized.config -resume`, then explain why `-resume` did or didn't re-run those tasks. (Hint: are `cpus`/`memory` part of the task hash?) Compare `realtime` and `peak_rss` in the trace before and after.

## E5. A test with nf-test (★★★, 30 min)

Install nf-test (`curl -fsSL https://get.nf-test.com | bash`) and write a test for the MLST process that runs on one of the assemblies and asserts the ST.

```bash
nf-test init
nf-test generate process modules/mlst.nf
# edit tests/modules/mlst.nf.test: input = a [meta, fasta] tuple
nf-test test tests/modules/mlst.nf.test --profile docker
```

Question: why does nf-core require a test for every module?
