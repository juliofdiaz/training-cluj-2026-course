#!/usr/bin/env bash
# Participant-side: fetch the course data from the course repository's GitHub release.
#
#   bash ~/course/data/get_data.sh                # course reads (~1 GB) + samplesheets, into ~/course/data/reads/
#   bash ~/course/data/get_data.sh bacass-demo    # the trainers' finished nf-core/bacass run (~30 MB),
#                                                 # into ./results_bacass_demo/ (run it from ~/course/day2/1_nfcore/)
#
# The instructors publish both files once.
# COURSE_RELEASE_URL overrides the release; COURSE_DATA_URL overrides the reads only.
set -euo pipefail
RELEASE=${COURSE_RELEASE_URL:-"https://github.com/<your-org>/reproducible-genomics-course/releases/download/course-data-v1"}

if [[ "${1:-}" == "bacass-demo" ]]; then
  if [[ -d results_bacass_demo ]]; then echo "results_bacass_demo/ is already here."; exit 0; fi
  echo "Downloading the finished bacass run from $RELEASE"
  curl -fL --retry 5 "$RELEASE/bacass_demo.tar.gz" | tar -xz
  echo "Done: $(pwd)/results_bacass_demo"
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
