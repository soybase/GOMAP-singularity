#!/usr/bin/env bash

if [ $# -lt 3 ]
then
    echo "Please check the number of input arguments"
    echo "run-SINGLE.sh config_file step number_of_nodes"
    echo "run-SINGLE.sh test/config.yml seqsim 1"
    exit
fi

if [ ! -f "$GOMAP_LOC" ]
then
    module load singularity/2.6.0 && \
    SINGULARITY_PULLFOLDER=`dirname $GOMAP_LOC` \ 
    singularity pull --name `basename $GOMAP_LOC` shub://Dill-PICL/GOMAP-singularity:bridges
fi

config=$1
shift
step=$2
shift
nodes=$3
shift
name=`cat $config | grep -v "#" | fgrep basename | cut -f 2 -d ":" | tr -d ' '`

echo -e "#!/bin/bash
#SBATCH -N $nodes
#SBATCH --ntasks-per-node 1
#SBATCH -t 48:00:00
#SBATCH --job-name=$name-GOMAP-$step
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kokul@iastate.edu
#SBATCH -o %x.out
#SBATCH -e %x.err
#SBATCH -C EGRESS

module load mpi/gcc_mvapich  singularity/2.6.0
"

if [ "$step" == "mixmeth" ]
then
echo "
singularity instance.start   \\
    --bind \$GOMAP_DATA_LOC/mysql/lib:/var/lib/mysql  \\
    --bind \$GOMAP_DATA_LOC/mysql/log:/var/log/mysql  \\
    --bind \$GOMAP_DATA_LOC:/opt/GOMAP/data \\
    --bind $PWD:/workdir  \\
    --bind $tmpdir:/tmpdir  \\
    -W $PWD/tmp \\
    \$GOMAP_LOC GOMAP && \\
singularity run \\
    instance://GOMAP --step=$step --config=$config $@"
elif [ "$step" == "mixmeth-blast" ]
then
echo "
mpiexec -n $((nodes+1)) \\
singularity run   \\
    --bind \$GOMAP_DATA_LOC/mysql/lib:/var/lib/mysql  \\
    --bind \$GOMAP_DATA_LOC/mysql/log:/var/log/mysql  \\
    --bind \$GOMAP_DATA_LOC:/opt/GOMAP/data \\
    --bind $PWD:/workdir  \\
    --bind $tmpdir:/tmpdir  \\
    -W $PWD/tmp \\
    \$GOMAP_LOC --step=$step --config=$config $@"
else
echo "
mpiexec -n $nodes \\
singularity run   \\
    --bind \$GOMAP_DATA_LOC/mysql/lib:/var/lib/mysql  \\
    --bind \$GOMAP_DATA_LOC/mysql/log:/var/log/mysql  \\
    --bind \$GOMAP_DATA_LOC:/opt/GOMAP/data \\
    --bind $PWD:/workdir  \\
    --bind $tmpdir:/tmpdir  \\
    -W $PWD/tmp \\
    \$GOMAP_LOC --step=$step --config=$config $@"
fi