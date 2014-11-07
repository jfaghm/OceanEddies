#!/bin/bash -l
#PBS -l nodes=80:ppn=8,pmem=2000mb,walltime=1:30:00
#PBS -j oe

cd $PBS_O_WORKDIR

source set_env

echo "using ssh"
for i in `uniq $PBS_NODEFILE`
do
for j in 0   #  1 2 3 4 5 6 7   (uncomment these for more workers per node)
do
  ssh $i "export PBS_O_WORKDIR=$PBS_O_WORKDIR; export PBS_VNODENUM=$i.$j; $dbwf_bin_dir/db_worker_shell_v1" &
done
done
wait


