#!/bin/sh

# Collects total runtime vs. number of nodes from UWLCM scaling runs.
# Scans the directory "BASE" (default: .) for output.* job directories, takes the slowest
# rank's time from the stdout.1.* files, and prints two lists (nodes, total_time [s]).
# Script generated with Claude Sonnet 5.5.
# Usage: ./total_time.sh [BASE_DIR] [RANKS_PER_NODE=4]

BASE=${1:-.}
RPN=${2:-4}

find "$BASE" -type d -name 'output.*' | sort | while read -r d
do
   files=$(find "$d" -name 'stdout.1.*' | sort)
   [ -z "$files" ] && continue
   label=${d#"$BASE"/}

   # shellcheck disable=SC2086
   awk -v label="$label" -v rpn="$RPN" '
      FNR == 1 { nf++ }
      {
         n = index($0, ":")
         if (n == 0) next
         key = substr($0, 1, n - 1)
         gsub(/^ +| +$/, "", key)
         if (key != "loop") next
         split(substr($0, n + 1), a, " ")
         if (a[1] !~ /^[0-9]+$/) next
         v = a[1] + 0
         if (v > lmax) lmax = v
         m++
      }
      END {
         if (m != nf) {
            print "SKIPPED (no result for some ranks: " m " of " nf "): " label > "/dev/stderr"
            exit
         }
         if (nf % rpn != 0)
            print "WARNING: " nf " ranks not divisible by " rpn " (" label ")" > "/dev/stderr"
         printf "%d %.1f\n", nf / rpn, lmax / 1000
      }
   ' $files
done | sort -n | awk '
   { nodes[NR] = $1; t[NR] = $2 }
   END {
      if (NR == 0) { print "no results" > "/dev/stderr"; exit 1 }
      s1 = ""; s2 = ""
      for (i = 1; i <= NR; i++) {
         sep = (i < NR) ? ", " : ""
         s1 = s1 nodes[i] sep
         s2 = s2 t[i] sep
      }
      print "nodes = [" s1 "]"
      print "total_s = [" s2 "]"
   }'
