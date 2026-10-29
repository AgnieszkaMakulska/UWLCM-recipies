#!/bin/bash
#PJM -L "rscunit=rscunit_ft01"
#PJM -L "rscgrp=small-s2"
#PJM -L "node=4"
#PJM -L "elapse=01:20:00"
#PJM --mpi "max-proc-per-node=4"
#PJM -g ra000005
#PJM -x PJM_LLIO_GFSCACHE=/vol0004:/vol0006
#PJM -j
#PJM -D /vol0004/ra000005/data/u15386/output/moist_thermal_lgrngn
#PJM -o /vol0004/ra000005/data/u15386/output/moist_thermal_lgrngn/%j.out

export WORK_LOCATION=/vol0004/ra000005/data/u15386  # data directory
export SPACK_LOCATION=/vol0006/mdt1/home/u15386  # directory where spack is installed
export BUILD_LOCATION=/vol0006/mdt1/home/u15386  # directory where UWLCM is installed

# For UWLCM built with gcc 12.2.0 + Fujitsu MPI (spack_uwlcm_fixed.yaml).
# Fujitsu MPI is started by the system mpiexec, which takes the nodes from PJM.

# A64FX node = 4 CMGs x 12 cores: 4 ranks per node (1 per CMG) x 12 threads = 48 cores
#   RPN (ranks per node) and THREADS can be overridden via pjsub -x (e.g. for 1 rank x 48 threads)
RPN=${RPN:-4}
export OMP_NUM_THREADS=${THREADS:-12}
export OMP_PROC_BIND=close   # required for GCC (Fujitsu compiler does this itself)
export OMP_PLACES=cores
export PLE_MPI_STD_EMPTYFILE=off
NPROC=$((PJM_NODE * RPN))

GCC12=/vol0004/apps/oss/spack-v1.0.1/opt/spack/linux-a64fx/gcc-12.2.0-f57uyl2rzc74cow54td7bdy77xajibir
FJMPI=/vol0004/apps/oss/mpigcc/fjmpi-gcc12

# 1. Stage spack packages, UWLCM builds and the gcc 12 runtime to the node-local LLIO cache.
#    Run it FIRST and in one call: it fails (rc=1) on files already opened in this job.
/home/system/tool/dir_transfer -l . \
    $SPACK_LOCATION/spack/opt/spack/linux-a64fx \
    $BUILD_LOCATION/builds \
    ${GCC12}/lib64 ${FJMPI}/lib64
rc=$?
[ $rc -ne 0 ] && echo "WARNING: dir_transfer rc=$rc, libraries will be read from GFS"

# 2. Spack environment + runtime libraries of the gcc 12 / Fujitsu MPI toolchain
source $SPACK_LOCATION/spack/share/spack/setup-env.sh
spack env activate $SPACK_LOCATION
export LD_LIBRARY_PATH="${GCC12}/lib64:${FJMPI}/lib64:${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}$BUILD_LOCATION/builds/lib"
export OPAL_PREFIX=${FJMPI}   # as spack's fujitsu-mpi (gcc) sets it

PJM_OUTPATH_STRIPPED=${PJM_STDOUT_PATH%/*}
echo ${PJM_OUTPATH_STRIPPED}

# 3. Output directory
now=`date +"%d_%m_%Y"`
# SD_CONC, ranks x threads and job id in the name, so runs on the same day/node count do not share a directory
outname_nomicro=${now}_out_UWLCM_moist_thermal_Nnode_${PJM_NODE}_SD${SD_CONC:-100}_${RPN}x${OMP_NUM_THREADS}_${PJM_JOBID}_
outdir_nomicro=$WORK_LOCATION/output/moist_thermal_lgrngn/${outname_nomicro}
outdir=${outdir_nomicro}out_lgrngn/
mkdir -p ${outdir}

NX=${NX:-96}
NY=${NY:-96}
X=${X:-3600}
Y=${Y:-3600}
SD_CONC=${SD_CONC:-100}

echo "NX=$NX, NY=$NY, X=$X, Y=$Y, SD_CONC=$SD_CONC"
echo "nodes=$PJM_NODE ranks=$NPROC threads/rank=$OMP_NUM_THREADS"
ldd $BUILD_LOCATION/builds/bin/uwlcm | grep -E "libmpi|gomp|stdc|not found"

# 4. Launch. Per-rank stdout/stderr go to output.${PJM_JOBID}/0/1/std{out,err}.1.<rank>
mpiexec -n ${NPROC} \
        $BUILD_LOCATION/builds/bin/uwlcm \
        --outdir=${outdir}  --case=moist_thermal --nx=${NX} --ny=${NY} --nz=96 --dt=0.5 \
        --spinup=0 --nt=12 --micro=lgrngn --sd_conc=${SD_CONC} --backend=OpenMP --outfreq=12 \
        --sstp_cond=5 --sstp_coal=5 --coal=1 --sgs=1 --window=0 \
        --coal_kernel=hall --term_vel=beard76 --save_vel=0 --X=${X} --Y=${Y}
# lgrngn micro with MPI gives an error on exit: log the code instead of hiding it
echo "mpiexec exit code: $?"

mkdir -p ${PJM_OUTPATH_STRIPPED}/${PJM_JOBID}
mv *${PJM_JOBID}* ${PJM_OUTPATH_STRIPPED}/${PJM_JOBID}/
