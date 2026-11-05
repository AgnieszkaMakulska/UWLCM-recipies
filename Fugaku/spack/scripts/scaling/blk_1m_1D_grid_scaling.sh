#!/bin/sh

export WORK_LOCATION=/vol0004/ra000005/data/u15386
JOBSCRIPT=$WORK_LOCATION/scripts/blk_1m_moist_thermal.sh

for N in 4 32 64 128 256 512
do
   # Determine the resource group based on node count
   if [ $N -gt 384 ]; then
      GROUP="spot-large"
   else
      GROUP="small-s1"
   fi


   # Create the directory first
   RUN_DIR="$WORK_LOCATION/output/blk_1m_1D_grid_scaling"
   mkdir -p "$RUN_DIR"

   NX=$((N * 96))
   X=$((N * 3600))

   echo "Submitting $N nodes to the $GROUP group. NX=$NX X=$X"

   # Pass the directory using the --working-dir flag
   pjsub --all-mount-gfscache \
	 -x "NX=$NX,X=$X" \
	 -L "node=$N" \
	 -L "rscgrp=$GROUP" \
	 -D "$RUN_DIR" \
         -o "$RUN_DIR/%j.out" \
	 "$JOBSCRIPT"
done
