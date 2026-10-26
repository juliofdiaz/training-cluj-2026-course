#!/usr/bin/env bash
# Participant-side: fetch the course data from the course repository's GitHub release.
#
#   bash ~/course/data/get_data.sh                # course reads (~1 GB) + samplesheets, into ~/course/data/reads/
#   bash ~/course/data/get_data.sh mash           # the species-check database for Day 2 (Mash RefSeq sketch,
#                                                 # 0.75 GB), into ~/course/data/mash/
#
# The instructors publish both files once.
# COURSE_RELEASE_URL overrides the release; COURSE_DATA_URL overrides the reads only.
set -euo pipefail
RELEASE=${COURSE_RELEASE_URL:-"https://github.com/juliofdiaz/training-cluj-2026-course/releases/download/course-data-v1"}

if [[ "${1:-}" == "mash" ]]; then
  DB=$(dirname "$0")/mash/refseq.genomes.k21s1000.msh; SIZE=754115096
  if [[ -f "$DB" && $(wc -c < "$DB") -eq $SIZE ]]; then echo "Species database already here: $DB"; exit 0; fi
  mkdir -p "$(dirname "$DB")"
  echo "Downloading the species database (0.75 GB) from $RELEASE"
  curl -fL --retry 5 -o "$DB.part" "${COURSE_MASH_URL:-$RELEASE/refseq.genomes.k21s1000.msh}"
  [[ $(wc -c < "$DB.part") -eq $SIZE ]] || { echo "Download incomplete: run this again" >&2; exit 1; }
  mv "$DB.part" "$DB" && echo "Done: $DB"
  exit 0
fi

cd "$(dirname "$0")"
URL=${COURSE_DATA_URL:-"$RELEASE/course-reads.tar.gz"}

if [[ -f reads/MD5SUMS ]] && (cd reads && md5sum -c --quiet MD5SUMS 2>/dev/null); then
  echo "Reads already present and verified."
else
  echo "Downloading course reads from $URL"
  curl -fL --retry 5 "$URL" | tar -xz
  (cd reads && md5sum -c --quiet MD5SUMS) && echo "Checksums OK"
fi
bash make_samplesheets.sh reads
