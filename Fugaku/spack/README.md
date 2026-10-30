# Installing UWLCM on Fugaku

This guide covers building UWLCM (together with its dependencies libmpdata++ and libcloudph++) on Fugaku using Spack, gcc 12.2.0 and Fujitsu MPI.

Files needed alongside this guide: `spack.yaml` (the Spack environment) and `spack_install.sh` (the PJM batch script that concretizes and installs the environment).

---

## Installing Spack

### Clone Fugaku's Spack fork and enable it

```bash
git clone --depth 1 --branch fugaku-v1.0.1 https://github.com/RIKEN-RCCS/spack.git
. ~/spack/share/spack/setup-env.sh
```

### Point Spack at the system-wide (public) installation

```bash
mkdir -p ~/.spack
vim ~/.spack/upstreams.yaml
```

Put the following in `~/.spack/upstreams.yaml`:

```yaml
upstreams:
  spack-public-instance:
    install_tree: /vol0004/apps/oss/spack/opt/spack
```

### Install the Spack environment

```bash
pjsub --all-mount-gfscache spack_install.sh
```

What `spack_install.sh` does:

1. Adds the four Fugaku package repos (`local`, `update`, `rist`, `rccs`).
2. Copies the system `packages.yaml` to `~/.spack/`.
3. Activates the environment in `~` (or other directory of your choice).
4. Runs `spack concretize --force` (log: `output/concretize.log`).
5. Runs `spack install -j 24` (log: `output/install.log`).

---

## Installing UWLCM

### Start an interactive job

Building is done on a compute node, you can use an interactive job:

```bash
pjsub --interact --sparam wait-time=90 \
      -L "rscunit=rscunit_ft01,rscgrp=int,node=1,elapse=6:00:00" \
      -g ra000005 --no-check-directory \
      -x PJM_LLIO_GFSCACHE=/vol0004
```

### Activate the Spack environment

```bash
. ~/spack/share/spack/setup-env.sh
spack env activate ~     # or change "~" to your directory that contains spack.yaml
```

### Put gcc 12.2.0 on your `PATH`

```bash
export PATH=/vol0004/apps/oss/spack-v1.0.1/opt/spack/linux-a64fx/gcc-12.2.0-f57uyl2rzc74cow54td7bdy77xajibir/bin:$PATH
```

### Build libmpdata++

```bash
cd ~/code/libmpdataxx/libmpdata++
mkdir build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=mpic++ \
  -DCMAKE_INSTALL_PREFIX=BUILD_DIR/builds \
  -DLIBMPDATAXX_MPI_THREAD_MULTIPLE=0
make -j12 install
```
> Change `BUILD_DIR` to your directory. This is where the executables will be placed.

### Build libcloudph++

```bash
cd ~/code/libcloudphxx
mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX=BUILD_DIR/builds \
  -DCMAKE_CXX_COMPILER=mpic++ \
  -DLIBCLOUDPHXX_DISABLE_BINDINGS=1 \
  -DCMAKE_BUILD_TYPE=Release
make -j12 install
```
> Change `BUILD_DIR` to your directory. This is where the executables will be placed.

### Build UWLCM

Only the 3D Lagrangian (`3D_LGRNGN`) and 3D one-moment bulk (`3D_BLK_1M`) variants are built here; all others are disabled.

```bash
cd ~/code/UWLCM
mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX=BUILD_DIR/builds \
  -DCMAKE_CXX_COMPILER=mpic++ \
  -DCMAKE_BUILD_TYPE=Release \
  -DLIBMPDATAXX_MPI_THREAD_MULTIPLE=0 \
  -DUWLCM_TIMING=1 \
  -DUWLCM_DISABLE="PIGGYBACKER;2D_BLK_1M;2D_BLK_2M;3D_BLK_2M;2D_LGRNGN;2D_NONE;3D_NONE"
make -j12 install
```
> Change `BUILD_DIR` to your directory. This is where the executables will be placed.


## Run scripts

> All scripts contain paths, user ID and project group, change them to your own before use.

- `blk_1m_moist_thermal.sh`: single moist-thermal simulation with one-moment bulk microphysics.
- `lgrngn_moist_thermal.sh`: single moist-thermal simulation with Lagrangian super-droplet microphysics.
- `blk_1m_1D_grid_scaling.sh`: submits bulk-microphysics runs on increasing node counts with the domain extended in x (weak scaling).
- `blk_1m_2D_grid_scaling.sh`: submits bulk-microphysics runs on increasing node counts with the domain extended in x and y (weak scaling).
- `lgrngn_strong_scaling.sh`: submits Lagrangian-microphysics runs of a fixed-size problem on increasing node counts (strong scaling).
- `total_time.sh`: collects the total run time versus number of nodes from the output of the scaling runs.
- `plot_scaling.py`: plots wall time per time step versus number of nodes from the values given by `total_time.sh`.