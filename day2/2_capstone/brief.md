# Capstone brief: "The ward cluster"

**Time:** 14:05 section A · 15:00 coffee · 15:15 section B · 15:30 section C · 15:45 stop, verdicts into the class spreadsheet · 15:50 one-minute verdicts.
**Work as a pair**, on your own results: one of you finds the evidence, the other writes it into `report.md`; swap at each section, A, B and C. Everything is in this folder, `~/course/day2/2_capstone/`.

## Scenario

An infection-control team suspects an MRSA transmission cluster on two hospital wards. The microbiology lab sequenced **8 isolates (SA01–SA08)** and sent you the reads. You have already run them through **bactflow** (laptop and AWS), including the species check you added this morning.

The infection-control lead will make decisions based on your report, and wants to know:

1. **Which isolates can be trusted for typing and AMR calls?** Which can't, and why?
2. For the trusted isolates: **sequence types and key resistance genes**. Is a single-clone outbreak plausible from MLST alone? What extra data would you need to be sure?
3. **Can someone else reproduce your analysis exactly?**

## Deliverables

All paths below are inside `results_aws/`: your cloud results. In this folder, `results_aws` is a shortcut to `~/course/day1/3_bactflow/results_aws/`. It holds 20 isolates; this question is about **SA01–SA08** only. The species check is in `results_aws/species/`, one `.screen` file per isolate.

**No `results_aws/`** (your cloud run failed)? Use the same paths inside your laptop results, `~/course/day1/3_bactflow/results/`: SA01–SA08, species check included. In the hint commands, type `~/course/day1/3_bactflow/results/` wherever they say `results_aws/`.

Fill in **`report.md`**, in this folder:

```bash
cd ~/course/day2/2_capstone
ls results_aws/                   # your cloud results, through the shortcut
```

| Section | Evidence you should use |
|---|---|
| A. QC triage table (PASS / WARN / FAIL per isolate, with reasons) | bactflow MultiQC (fastp: bases, read GC, read length; QUAST), `qc/quast/report.tsv`, **`species/<isolate>.screen`** (Mash) |
| B. Typing & AMR summary for PASS isolates | `typing/mlst_summary.tsv`, `amr/amr_summary.tsv` |
| C. Reproducibility statement | Exact commands, pipeline version, Nextflow version, `software_versions.tsv` (Mash is in it now), the species database you used, read checksums (`~/course/data/reads/MD5SUMS`) |
| *Optional:* one extension from `extensions.md` (in this folder) | Only if you finish A–C early |

## Your pair's one-minute verdict (15:50, from your seats)

At 15:45, open the class spreadsheet and fill in **Verdict** (PASS, WARN or FAIL) and a one-line **Reason** in your 8 rows. Then, in one minute, your pair says (one speaks, or you share it):
1. Which isolates you would act on, and which not.
2. The one piece of evidence that decided it.
3. One sentence on the cluster question.

## Hints (always here: read them only if stuck after 15 minutes)

<details><summary>Hint 1</summary>
In MultiQC's General Statistics, multiply **Reads After Filtering** by **Mean R1 Length**: that is roughly the bases after QC. Divide by the genome size (≈2.8 Mb) for the depth. (The species check's third column, median depth, tells the same story.) What depth does each isolate have? What happened to its MLST call and its AMR genes?
</details>

<details><summary>Hint 2</summary>
Assembly-level numbers can look perfectly normal for a contaminated sample. Look at the <b>reads</b> instead: compare **GC content** and **Mean R1 Length** per isolate in MultiQC's General Statistics.
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

Your species check lists the genomes Mash found in each isolate's reads. This prints the top lines of every isolate, without the phage lines (those are normal):

```bash
cd ~/course/day2/2_capstone
for s in SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08; do echo "== $s"; grep -vi phage results_aws/species/$s.screen | sort -gr | head -3; done
```

Is every isolate only *Staphylococcus*? Compare the third column (median depth) between isolates too.
</details>
