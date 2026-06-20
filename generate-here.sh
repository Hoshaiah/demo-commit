#!/usr/bin/env bash
#
# generate-here.sh — EDUCATIONAL DEMONSTRATION (in-place variant)
#
# Same lesson as demo.sh, but it initializes the git repo in the CURRENT
# directory instead of creating a throwaway subfolder. It backdates commits to
# show how a contribution graph is populated from author dates.
#
# Everything produced is tagged [DEMO]. This script does NOT delete anything and
# does NOT add a remote or push. Run it inside an empty folder you created for
# the purpose.
#
# Usage (from inside the target folder):
#   bash /path/to/generate-here.sh [DAYS]
#     DAYS  number of past days to generate (default: 7)

set -euo pipefail

DAYS="${1:-365}"
FACTS_FILE="cs-facts.md"

# --- Safety guards ---------------------------------------------------------
# If the directory already has commits, don't refuse outright — warn and ask
# the user whether to append more backdated [DEMO] commits to the existing
# history.
if [ -d .git ] && git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Warning: this directory already has git commits." >&2
  printf "Continue adding backdated [DEMO] commits to the existing history? [y/N] " >&2
  read -r reply
  case "$reply" in
    [Yy]|[Yy][Ee][Ss]) echo "Continuing on top of existing history." >&2 ;;
    *) echo "Aborted." >&2; exit 1 ;;
  esac
fi

echo "=============================================================="
echo " EDUCATIONAL DEMO — forging commit dates (all commits = [DEMO])"
echo " Initializing a repo in: $(pwd)"
echo " Nothing is deleted, nothing is pushed."
echo "=============================================================="

# A handful of computer-science facts used as filler content.
FACTS=(
  "Binary search runs in O(log n) time but requires the input to be sorted first."
  "The term 'bug' predates computers; Grace Hopper famously taped a real moth into a 1947 logbook."
  "A hash table gives average O(1) lookup, but worst-case O(n) when every key collides."
  "TCP guarantees ordered, reliable delivery; UDP trades those guarantees for lower latency."
  "Big-O describes growth, not speed: an O(n) algorithm can beat an O(log n) one for small n."
  "There are exactly 1024 bytes in a kibibyte (KiB), but 1000 in a kilobyte (kB)."
  "Quicksort averages O(n log n) but degrades to O(n^2) on already-sorted input with naive pivots."
  "A SHA-256 hash is 256 bits — 64 hexadecimal characters — regardless of input size."
  "Floating-point can't represent 0.1 exactly, which is why 0.1 + 0.2 != 0.3 in most languages."
  "Git stores snapshots, not diffs; identical file contents are stored only once via content hashing."
  "The halting problem is undecidable: no general algorithm can tell if any program will stop."
  "Caches exploit locality of reference — recently/nearby-accessed data is likely to be used again."
  "ASCII uses 7 bits (128 values); UTF-8 extends this to all of Unicode while staying ASCII-compatible."
  "A balanced binary tree keeps height ~log n, which is what keeps its operations fast."
  "Deadlock needs four conditions at once: mutual exclusion, hold-and-wait, no preemption, circular wait."
)

# Init in place only if there's no repo yet.
if [ ! -d .git ]; then
  git init -q
fi

# Single file every commit appends to (create header if it's new).
if [ ! -f "$FACTS_FILE" ]; then
  {
    echo "# Computer Science Facts — [DEMO, fabricated dates]"
    echo ""
    echo "_Every entry below was appended by a backdated commit for a demonstration._"
    echo ""
  } > "$FACTS_FILE"
fi

# Cross-platform "date X days ago" helper (BSD/macOS vs GNU/Linux).
days_ago() {
  if date -v -1d +%Y-%m-%d >/dev/null 2>&1; then
    date -v -"$1"d +%Y-%m-%d
  else
    date -d "-$1 days" +%Y-%m-%d
  fi
}

# Walk from (DAYS-1) days ago up to today.
for (( i=DAYS-1; i>=0; i-- )); do
  DAY=$(days_ago "$i")

  # 1–7 commits per day, with timestamps scattered across waking hours.
  n=$(( (RANDOM % 7) + 1 ))
  for (( f=1; f<=n; f++ )); do
    fact="${FACTS[$((RANDOM % ${#FACTS[@]}))]}"
    echo "- **${DAY}:** ${fact}" >> "$FACTS_FILE"
    git add "$FACTS_FILE"

    hour=$(( (RANDOM % 14) + 8 ))
    min=$(( RANDOM % 60 ))
    sec=$(( RANDOM % 60 ))
    ts=$(printf "%sT%02d:%02d:%02d" "$DAY" "$hour" "$min" "$sec")
    GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" \
      git commit -q -m "[DEMO] CS fact for ${DAY} (#${f})"
  done
done

echo ""
echo "Done. Generated commits (backdated author dates):"
echo ""
git log --pretty='%h  %ad  %s' --date=short
