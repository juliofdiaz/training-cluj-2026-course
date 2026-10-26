# Capstone brief: "The ward cluster"

**Time:** 14:05 section A · 15:00 coffee · 15:15 section B · 15:30 section C · 15:45 stop, verdicts into the class spreadsheet · 15:50 one-minute verdicts.
**Work alone**, on your own results. Everything is in this folder, `~/course/day2/2_capstone/`.

## Scenario

An infection-control team suspects an MRSA transmission cluster on two hospital wards. The microbiology lab sequenced **8 isolates (SA01–SA08)** and sent you the reads. You have already run them through **bactflow** (laptop and AWS) and **nf-core/bacass** (AWS).

The infection-control lead will make decisions based on your report, and wants to know:

1. **Which isolates can be trusted for typing and AMR calls?** Which can't, and why?
2. For the trusted isolates: **sequence types and key resistance genes**. Is a single-clone outbreak plausible from MLST alone? What extra data would you need to be sure?
3. **Can someone else reproduce your analysis exactly?**

## Deliverables

All paths below are inside `results_aws/`: your cloud results. In this folder, `results_aws` is a shortcut to `~/course/day1/3_bactflow/results_aws/`. It holds 20 isolates; this question is about **SA01–SA08** only. The bacass report is in `results_aws/bacass_multiqc/`.

**No `results_aws/`** (your cloud run failed)? Use the same paths inside your laptop results, `~/course/day1/3_bactflow/results/` (SA01–SA08), and the bacass report in `~/course/day2/1_nfcore/results_bacass_demo/multiqc/`.

Fill in **`report.md`**, in this folder:

```bash
cd ~/course/day2/2_capstone
ls results_aws/                   # your cloud results, through the shortcut
```

| Section | Evidence you should use |
|---|---|
| A. QC triage table (PASS / WARN / FAIL per isolate, with reasons) | bactflow MultiQC (fastp: bases, read GC, read length; QUAST), `qc/quast/report.tsv`, bacass MultiQC (**Kraken2**) |
| B. Typing & AMR summary for PASS isolates | `typing/mlst_summary.tsv`, `amr/amr_summary.tsv` |
| C. Reproducibility statement | Exact commands, pipeline version, Nextflow version, `software_versions.tsv`, bacass's `params_aws.yaml`, samplesheet checksums (`MD5SUMS`) |
| *Optional:* one extension from `extensions.md` (in this folder) | Only if you finish A–C early |

## Your one-minute verdict (15:50, from your seat)

At 15:45, open the class spreadsheet and fill in **Verdict** (PASS, WARN or FAIL) and a one-line **Reason** in your 8 rows. Then, in one minute, say:
1. Which isolates you would act on, and which not.
2. The one piece of evidence that decided it.
3. One sentence on the cluster question.

## Hints (always here: read them only if stuck after 15 minutes)

<details><summary>Hint 1</summary>
Compare the total number of bases after filtering (fastp, MultiQC General Statistics) with the expected genome size (≈2.8 Mb). What depth of coverage does each isolate have? What happened to its MLST call and its AMR genes?
</details>

<details><summary>Hint 2</summary>
Assembly-level numbers can look perfectly normal for a contaminated sample. Look at the <b>reads</b> instead: compare GC content and mean read length per isolate in the fastp section of MultiQC.
</details>

<details><summary>Hint 3</summary>

Is there an AMR gene that only one isolate has? Find the contig it sits on (`amr/per_sample/`, column SEQUENCE), then look at that contig in `assemblies/`: its `cov=` value in the header, and its GC content. This prints name, length and GC% for every contig of one isolate (change `SA01` to the isolate you want):

```bash
cd ~/course/day2/2_capstone
awk '/^>/{if(n)printf "%s\t%d\t%.1f\n",h,n,100*g/n; h=$1; n=0; g=0; next}{n+=length($0); g+=gsub(/[GCgc]/,"")}END{printf "%s\t%d\t%.1f\n",h,n,100*g/n}' results_aws/assemblies/SA01.fasta
```

Does that contig look like the rest of the genome?
</details>

<details><summary>Hint 4</summary>
bactflow has no species or contamination check. bacass ran Kraken2. What does it say for each isolate?
</details>
