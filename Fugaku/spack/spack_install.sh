#!/bin/bash
#PJM -L "rscunit=rscunit_ft01"
#PJM -L "rscgrp=small-s3"
#PJM -L "node=1"
#PJM -L "elapse=03:00:00"
#PJM -g ra000005
#PJM -x PJM_LLIO_GFSCACHE=/vol0004:/vol0006
#PJM -s
#PJM -o output/spack_install.out
#PJM -e output/spack_install.err

SPACK_LOCATION=$HOME

. ${SPACK_LOCATION}/spack/share/spack/setup-env.sh

spack repo add /vol0004/apps/oss/spack/var/spack/fugaku-packages/repos/spack_repo/fugaku/local
spack repo add /vol0004/apps/oss/spack/var/spack/fugaku-packages/repos/spack_repo/fugaku/update
spack repo add /vol0004/apps/oss/spack/var/spack/fugaku-packages/repos/spack_repo/fugaku/rist
spack repo add /vol0004/apps/oss/spack/var/spack/fugaku-packages/repos/spack_repo/fugaku/rccs
mkdir -p ${SPACK_LOCATION}/.spack
cp /vol0004/apps/oss/spack/etc/spack/packages.yaml ${SPACK_LOCATION}/.spack/

spack env activate ${SPACK_LOCATION}

mkdir -p output

if ! spack concretize --force > output/concretize.log 2>&1; then
    echo "concretize failed, see output/concretize.log" >&2
    exit 1
fi
 
spack install -j 24 > output/install.log 2>&1
