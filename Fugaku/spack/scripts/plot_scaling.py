# Plotting the results of weak and strong scaling tests, where
# (nodes, times) lists are obtained with the "total_time.sh" script.

import numpy as np
import matplotlib.pyplot as plt
plt.rcParams.update({'font.size': 12})

nx1 = 96
MPI_per_node = 4

# BULK 1D grid scaling
plt.figure()
nt = 120 #number of timesteps
nodes = np.array([4, 16, 32, 64, 128, 256, 512, 1024])
times = np.array([383.9, 385.6, 388.3, 391.5, 396.0, 401.1, 464.2, 484.7])
times_per_step = times / nt
plt.plot(nodes, times_per_step, 'o', markersize=6)
plt.xlabel('number of nodes')
plt.ylabel('wall time per step [s]')
plt.title('Bulk 1D grid scaling')
plt.xscale('log')
plt.xticks(nodes, nodes)
plt.grid()
plt.savefig("blk_1D_grid_scaling.pdf")



# BULK 2D grid scaling

def nx_per_mpi(N):
    return nx1 * np.sqrt(N) / (MPI_per_node * N)

fig, ax1 = plt.subplots()
nt = 120 #number of timesteps
nodes = np.array([4, 16, 64, 144, 256, 512])
times = np.array([383.5, 388.5, 400.7, 405.9, 411.0, 450.0])
times_per_step = times / nt
nx_per_mpis = np.array([round(nx_per_mpi(N), 2) for N in nodes])

ax1.plot(nodes, times_per_step, 'o', markersize=6)
ax1.set_xlabel('number of nodes')
ax1.set_ylabel('wall time per step [s]')
ax1.set_title('Bulk 2D grid scaling', pad = 20) 
ax1.set_xscale('log')
ax1.set_xticks(nodes)
ax1.set_xticklabels(nodes)
ax1.grid(True)

ax2 = ax1.twiny()
ax2.set_xscale('log')
ax2.set_xlim(ax1.get_xlim())
ax2.set_xticks(nodes)
ax2.set_xticklabels(nx_per_mpis, rotation=45)
ax2.tick_params(axis='x', colors='red')
ax2.set_xlabel('nx per MPI process', color='red')
plt.tight_layout()
plt.savefig("blk_2D_grid_scaling.pdf")



# LGRNGN strong scaling
plt.figure()
nt = 12 #number of timesteps
nodes = np.array([15, 24, 40, 60, 120])
times = np.array([1084.8, 708.1, 474.2, 352.7, 227.9])
times_per_step = times / nt
plt.plot(nodes, times_per_step, 'o', markersize=6)
plt.xlabel('number of nodes')
plt.ylabel('wall time per step [s]')
plt.title('Lagrangian strong scaling')
#plt.xscale('log')
plt.xticks(nodes, nodes)
plt.grid()
plt.savefig("lgrngn_strong_scaling.pdf")
