#!/bin/sh

export WORK_LOCATION=/vol0004/ra000005/data/u15386
JOBSCRIPT=$WORK_LOCATION/scripts/blk_1m_moist_thermal.sh

for N in 4 16 64 144 256 1024 
do
   # Determine the resource group based on node count
   if [ $N -gt 384 ]; then
      GROUP="spot-large"
   else
      GROUP="small-s1"
   fi


   # Create the directory first
   RUN_DIR="$WORK_LOCATION/output/blk_1m_2D_grid_scaling"
   mkdir -p "$RUN_DIR"

   SQRTN=$(echo "sqrt($N)" | bc)
   NX=$((SQRTN * 96))
   NY=$((SQRTN * 96))
   X=$((SQRTN*3600))
   Y=$((SQRTN*3600))

   echo "Submitting $N nodes to the $GROUP group. SQRTN=$SQRTN NX=$NX NY=$NY X=$X Y=$Y"

   # Pass the directory using the --working-dir flag
   pjsub --all-mount-gfscache \
	 -x "NX=$NX,NY=$NY,X=$X,Y=$Y" \
	 -L "node=$N" \
	 -L "rscgrp=$GROUP" \
	 -D "$RUN_DIR" \
         -o "$RUN_DIR/%j.out" \
	 "$JOBSCRIPT"
done
