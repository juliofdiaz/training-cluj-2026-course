#!/usr/bin/env bash
# =============================================================================
# check_vm.sh — can this machine run the course?
#
# Written for the course VMs, and also works on Linux/macOS laptops. Checks every version and resource the course depends on. It changes
# nothing, and prints a fix for each problem.
#
#   bash ~/course/tools/check_vm.sh              # Day 1 checks
#   bash ~/course/tools/check_vm.sh --day2       # + AWS access (S3, Batch queue)
#   bash ~/course/tools/check_vm.sh --run-test   # + run the 2-sample pipeline test (1-3 min)
#
# Exit code: 0 = ready, 1 = at least one FAIL.
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")/.."   # the course folder (~/course)

REQ_NXF=26.04.0          # help/pipeline/nextflow.config: nextflowVersion '!>=26.04.0'
PIN_NXF=26.04.9          # the version the course was tested with
JAVA_MIN=17; JAVA_MAX=26 # Nextflow 26.04 supports Java 17-26
DAY2=0; RUN_TEST=0
for a in "$@"; do case $a in --day2) DAY2=1;; --run-test) RUN_TEST=1;; -h|--help) sed -n 2,15p "$0"; exit 0;; esac; done

FAILS=0; WARNS=0
ok()   { printf '[ \033[32mOK\033[0m ] %s\n' "$1"; }
warn() { printf '[\033[33mWARN\033[0m] %s\n' "$1"; [ -n "${2:-}" ] && printf '         fix: %s\n' "$2"; WARNS=$((WARNS+1)); }
bad()  { printf '[\033[31mFAIL\033[0m] %s\n' "$1"; [ -n "${2:-}" ] && printf '         fix: %s\n' "$2"; FAILS=$((FAILS+1)); }
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }   # ver_ge A B  ->  A >= B
have() { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

section "Nextflow and Java"
if [ -n "${NXF_VER:-}" ] && ! ver_ge "$NXF_VER" "$REQ_NXF"; then
  bad "NXF_VER is pinned to $NXF_VER in this shell; the course pipeline needs >= $REQ_NXF" \
      "export NXF_VER=$PIN_NXF   (add it to ~/.bashrc for this course; other courses can keep their own pin per command)"
fi
if have java; then
  JV=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+)(\.[0-9]+)*.*/\1/; s/^1$/8/')
  if [[ "$JV" =~ ^[0-9]+$ ]] && [ "$JV" -ge $JAVA_MIN ] && [ "$JV" -le $JAVA_MAX ]; then ok "Java $JV"
  else bad "Java ${JV:-unknown}: Nextflow $PIN_NXF needs Java $JAVA_MIN-$JAVA_MAX" "install Temurin 21 (e.g. 'sdk install java 21.0.5-tem') or ask the VM admins"; fi
else bad "Java not found" "install Java 17-26 (Temurin 21 recommended)"; fi
if have nextflow; then
  NV=$(nextflow -version 2>/dev/null | grep -oE 'version [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' | head -1)
  if [ -z "$NV" ]; then bad "nextflow is installed but did not report a version" "run 'nextflow -version' and read the error (often Java or network)"
  elif ver_ge "$NV" "$REQ_NXF"; then ok "Nextflow $NV"
  else bad "Nextflow $NV is older than $REQ_NXF (the course pipeline uses workflow outputs and topic channels)" \
           "export NXF_VER=$PIN_NXF   then run this check again (the launcher downloads it once, ~100 MB)"; fi
  if [ -n "${NV:-}" ] && ver_ge "$NV" "$REQ_NXF"; then
    if nextflow lint help/pipeline >/dev/null 2>&1; then ok "Course pipeline passes 'nextflow lint' with this version"
    else bad "Course pipeline fails 'nextflow lint' with Nextflow $NV" "run 'cd ~/course && nextflow lint help/pipeline' to see why"; fi
  fi
else bad "Nextflow not found" "curl -s https://get.nextflow.io | bash && sudo mv nextflow /usr/local/bin/"; fi

section "Containers"
if have docker && docker info >/dev/null 2>&1; then
  ok "Docker running and usable without sudo ($(docker --version | awk '{print $3}' | tr -d ,))"
  missing=0
  for img in fastp:1.4.0--h43da1c4_0 shovill:1.4.2--hdfd78af_1 quast:5.3.0--py313pl5321h5ca1c30_2 \
             mlst:2.35.0--hdfd78af_1 abricate:1.4.0--h05cac1d_0 multiqc:1.35--pyhdfd78af_2 mash:2.3--he348c14_1; do
    docker image inspect "quay.io/biocontainers/$img" >/dev/null 2>&1 || missing=$((missing+1))
  done
  [ $missing -eq 0 ] && ok "All 7 pipeline images pulled" || warn "$missing of 7 pipeline images not pulled yet" "bash ~/course/tools/pull_images.sh"
elif have docker && [ "$(uname)" = Darwin ]; then
  bad "Docker is installed but not running" "start Docker Desktop, wait for it to say 'running', then run this again"
elif have docker; then
  bad "Docker is installed but not usable by $(whoami)" "sudo usermod -aG docker $(whoami) && newgrp docker   (or start the Docker service)"
elif have apptainer || have singularity; then
  warn "No Docker, but Apptainer/Singularity found" "use -profile apptainer instead of -profile docker in every command"
else bad "No container engine (Docker or Apptainer)" "ask the VM admins to install Docker"; fi

section "git (only for the optional page, D1 handbook section 6)"
have git && ok "git $(git --version | awk '{print $3}')" || warn "git not found (optional)" "sudo apt-get install -y git"

section "Resources"
CPUS=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
[ "$CPUS" -ge 4 ] && ok "$CPUS CPUs" || warn "$CPUS CPUs (4 recommended)" "runs still work, just slower: the pipeline caps each task at $CPUS CPUs"
if [ -r /proc/meminfo ]; then MEM=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
else MEM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )); fi
if   [ "$MEM" -ge 14 ]; then ok "${MEM} GB RAM"
elif [ "$MEM" -ge 7 ];  then warn "${MEM} GB RAM (16 recommended)" "runs still work: the pipeline caps each task at 85% of this machine's memory"
else bad "${MEM} GB RAM: Shovill needs about 6 GB" "ask for a bigger VM"; fi
FREE=$(df -Pk . | awk 'NR==2 {print int($4/1024/1024)}')
[ "$FREE" -ge 10 ] && ok "${FREE} GB free disk" || bad "Only ${FREE} GB free disk (need 10)" "clean up, or ask for a bigger disk"

section "Network"
for url in https://quay.io https://github.com https://raw.githubusercontent.com https://registry.nextflow.io https://www.nextflow.io; do
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$url" || echo 000)
  [ "$code" != "000" ] && ok "Reach $url" || warn "Cannot reach $url" "container pulls / nf-core / module installs need it: check the proxy or firewall"
done

section "Course data"
md5_ok() {  # verify data/reads/MD5SUMS with md5sum (Linux) or md5 (macOS)
  if have md5sum; then (cd data/reads && md5sum -c --quiet MD5SUMS >/dev/null 2>&1)
  else (cd data/reads && while read -r sum f; do [ "$(md5 -q "$f" 2>/dev/null)" = "$sum" ] || exit 1; done < MD5SUMS); fi
}
if [ -f data/reads/MD5SUMS ]; then
  if md5_ok; then
    ok "Course reads pass their checksums ($(ls data/reads/*_R1.fastq.gz 2>/dev/null | wc -l | tr -d ' ') samples)"
  else bad "Course reads fail their checksums" "bash ~/course/data/get_data.sh"; fi
else bad "Course reads missing" "bash ~/course/data/get_data.sh"; fi
[ -s data/reads/samplesheet.csv ] && ok "Samplesheets written" || bad "Samplesheets missing" "bash ~/course/data/make_samplesheets.sh"
if [ "$(wc -c < data/mash/refseq.genomes.k21s1000.msh 2>/dev/null || echo 0)" -eq 754115096 ]; then ok "Species database for Day 2 (Mash RefSeq sketch)"
else warn "Species database for Day 2 missing or incomplete" "bash ~/course/data/get_data.sh mash"; fi

if [ $DAY2 -eq 1 ]; then
  section "AWS (Day 2)"
  if have aws; then
    ok "AWS CLI $(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)"
    if ID=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null); then ok "AWS identity: $ID"
    else bad "No AWS credentials" "the course machine's role is missing: tell an instructor"; fi
    if [ -n "${COURSE_BUCKET:-}" ]; then
      aws s3 ls "$COURSE_BUCKET/data/" >/dev/null 2>&1 && ok "Can read $COURSE_BUCKET/data/" || bad "Cannot read $COURSE_BUCKET/data/" "check COURSE_BUCKET and your permissions"
    else warn "COURSE_BUCKET not set" "export COURSE_BUCKET=s3://<course-bucket>  (on the board)"; fi
    Q=${COURSE_QUEUE:-workshop-cluj-2026-queue}
    S=$(aws batch describe-job-queues --job-queues "$Q" --query 'jobQueues[0].state' --output text 2>/dev/null)
    [ "$S" = "ENABLED" ] && ok "Batch queue $Q is ENABLED" || bad "Batch queue $Q not found or not ENABLED (got: ${S:-nothing})" "export COURSE_QUEUE=<queue-name> or tell an instructor"
  else bad "AWS CLI not found" "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"; fi
  # Checked even without the AWS CLI: the cleanup commands delete $COURSE_BUCKET/.../$COURSE_USER/
  if [ -z "${COURSE_USER:-}" ]; then bad "COURSE_USER not set (cloud runs and the cleanup need it)" "source ~/.course_env (tell an instructor if that file is missing)"
  elif [[ ! "$COURSE_USER" =~ ^[a-z0-9-]+$ ]]; then bad "COURSE_USER='$COURSE_USER' must be lowercase letters, digits or -" "export COURSE_USER=<your pair id, e.g. ana-ion> (it is in ~/.course_env)"
  else ok "COURSE_USER=$COURSE_USER"; fi
fi

if [ $RUN_TEST -eq 1 ] && [ $FAILS -eq 0 ]; then
  section "Functional test: 2-sample pipeline run"
  T=$(mktemp -d "${TMPDIR:-/tmp}/bactflow-check.XXXX")
  START=$(date +%s)
  if (cd "$T" && nextflow run "$OLDPWD/help/pipeline/main.nf" -profile docker,test --outdir "$T/results" >"$T/run.log" 2>&1); then
    ok "Pipeline test passed in $(( $(date +%s) - START )) s (expected 1-3 min on 4 CPUs)"
  else bad "Pipeline test failed after $(( $(date +%s) - START )) s" "read $T/run.log"; fi
fi

echo
if [ $FAILS -eq 0 ]; then
  printf '\033[32mReady.\033[0m %d warning(s).\n' $WARNS; exit 0
else
  printf '\033[31mNot ready:\033[0m %d failure(s), %d warning(s). Fix the FAIL lines above, then run this again.\n' $FAILS $WARNS; exit 1
fi
