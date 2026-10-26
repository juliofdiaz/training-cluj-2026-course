#!/usr/bin/env bash
# Write samplesheets with ABSOLUTE paths for the machine you are on.
# Run again whenever the reads move (e.g. on a new machine).
#   bash ~/course/data/make_samplesheets.sh [reads_dir]     (default: the reads/ folder next to this script)
set -euo pipefail
DIR=$(cd "${1:-$(dirname "$0")/reads}" && pwd)

sheet() {  # sheet <first> <last>: samples SA<first>..SA<last> that exist
  echo "sample,fastq_1,fastq_2"
  for r1 in "$DIR"/SA*_R1.fastq.gz; do
    id=$(basename "$r1" _R1.fastq.gz); n=$((10#${id#SA}))
    (( n >= $1 && n <= $2 )) && echo "$id,$r1,$DIR/${id}_R2.fastq.gz"
  done
  return 0
}

sheet 1 8  > "$DIR/samplesheet.csv"        # Day 1 and the capstone: SA01–SA08
sheet 1 99 > "$DIR/samplesheet_day2.csv"   # Day 2 cloud run: every sample (20)
head -3 "$DIR/samplesheet.csv" > "$DIR/samplesheet_test.csv"   # header + SA01, SA02

for f in samplesheet samplesheet_day2 samplesheet_test; do
  echo "Wrote $DIR/$f.csv ($(($(wc -l < "$DIR/$f.csv") - 1)) samples)"
done
