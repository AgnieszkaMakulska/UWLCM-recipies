#!/bin/sh

export WORK_LOCATION=/vol0004/ra000005/data/u15386
JOBSCRIPT=$WORK_LOCATION/scripts/lgrngn_moist_thermal.sh

# Fixed global problem (strong scaling): 480 x 480 x 96 cells, 18 km x 18 km.
# Ranks = 4 * nodes, decomposition along x

NX=$((5*96))
NY=$((5*96))
X=$((5*3600))
Y=$((5*3600))

SD_CONC=100

RUN_DIR="$WORK_LOCATION/output/lgrngn_strong_scaling"
mkdir -p "$RUN_DIR"

for N in 15 24 40 60 120
do
   GROUP="small-s2"

   echo "Submitting $N nodes to the $GROUP group..."

   pjsub --all-mount-gfscache \
         -x "NX=$NX,NY=$NY,X=$X,Y=$Y,SD_CONC=$SD_CONC" \
         -L "node=$N" \
         -L "rscgrp=$GROUP" \
         -D "$RUN_DIR" \
         -o "$RUN_DIR/%j.out" \
         "$JOBSCRIPT"
done
