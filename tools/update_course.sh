#!/usr/bin/env bash
# Bring ~/course up to date with the course repository, without touching your own work.
#
#   bash ~/course/tools/update_course.sh
#
# Never overwritten once you have them: notes.md, the exercise files you edit (day1/2_nextflow_basics/0*,
# day1/1_containers/Dockerfile), everything in day1/3_bactflow/ and day2/1_nfcore/, the capstone report.md,
# and the reads. Everything else is updated; new files are added; nothing is deleted.
# The instructors run this on every machine with deploy/update_course.sh.
set -euo pipefail
SRC=${COURSE_SRC:-$HOME/.course-src}     # the clone of the course repository
DST=${COURSE_DIR:-$HOME/course}
[ -d "$SRC/.git" ] || { echo "No course repository in $SRC" >&2; exit 1; }
git -C "$SRC" pull --ff-only --quiet
C=$SRC; [ -d "$SRC/course" ] && C=$SRC/course   # the student repository holds course/ at its top

# Your work: copied the first time only
MINE=(notes.md day2/2_capstone/report.md day1/1_containers/Dockerfile
      day1/2_nextflow_basics/01_hello.nf day1/2_nextflow_basics/02_channels.nf
      day1/2_nextflow_basics/03_first_process.nf day1/2_nextflow_basics/04_config.nf
      day1/2_nextflow_basics/04.config)

FILTER=(--exclude=/.git/ --exclude=/data/reads/ --exclude=work/ --exclude=.nextflow/ --exclude='.nextflow.log*'
        --exclude=results/ --exclude='results_*/'
        --include=/day1/3_bactflow/README.md --exclude='/day1/3_bactflow/*'
        --include=/day2/1_nfcore/README.md --exclude='/day2/1_nfcore/*')
for f in "${MINE[@]}"; do FILTER+=(--exclude="/$f"); done

mkdir -p "$DST"
n=$(rsync -a --itemize-changes "${FILTER[@]}" "$C/" "$DST/" | grep -c '^>f' || true)
for f in "${MINE[@]}"; do
  if [ -e "$C/$f" ] && [ ! -e "$DST/$f" ]; then mkdir -p "$(dirname "$DST/$f")"; cp -p "$C/$f" "$DST/$f"; n=$((n+1)); fi
done
echo "~/course is at $(git -C "$SRC" log -1 --format='%h, %cd: %s' --date=format:'%d %b %H:%M') ($n file(s) updated)"
