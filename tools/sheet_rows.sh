#!/usr/bin/env bash
# sheet_rows.sh: print your bactflow results as rows for the class spreadsheet.
#
#   cd ~/course/day1/3_bactflow
#   bash ~/course/tools/sheet_rows.sh "Your Name"              # uses results/
#   bash ~/course/tools/sheet_rows.sh "Your Name" results_aws  # another results folder
#
# One line per isolate, tab-separated: Name, Sample, ST, Resistance genes.
# Select the lines, copy them, and paste them into column A of the first
# empty row of the sheet: Google Sheets splits them into columns.
set -euo pipefail
NAME=${1:?usage: bash ~/course/tools/sheet_rows.sh "Your Name" [results_folder]}
RES=${2:-results}
MLST=$RES/typing/mlst_summary.tsv
AMR=$RES/amr/amr_summary.tsv
for f in "$MLST" "$AMR"; do
  [ -s "$f" ] || { echo "Not found: $f. Run this inside ~/course/day1/3_bactflow/, after the full pipeline (Day 1 handbook §4.3)." >&2; exit 1; }
done

awk -F'\t' -v OFS='\t' -v name="$NAME" '
  FNR == NR { st[$1] = ($3 == "-" || $3 == "") ? "none" : $3; next }   # mlst: sample, scheme, ST, alleles
  FNR == 1  { for (i = 3; i <= NF; i++) gene[i] = $i; next }           # abricate summary header
  {
    s = $1; sub(/.*\//, "", s); sub(/\..*/, "", s)                       # /path/SA01.ncbi.tsv -> SA01
    g = ""
    for (i = 3; i <= NF; i++) if ($i != ".") g = g (g == "" ? "" : ",") gene[i]
    amr[s] = (g == "") ? "none" : g
  }
  END { for (s in st) print name, s, st[s], (s in amr) ? amr[s] : "none" }
' "$MLST" "$AMR" | sort -t "$(printf '\t')" -k2,2
