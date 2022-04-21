#!/bin/bash

# environment test
struDir=$1
name=$2
solvent="methanol"
if [ ! $ORCA_PATH ]; then
    echo "ORCA PATH not exist"
    exit
elif [ ! "$(which g16)" ]; then
    echo "g16 not in your path"
    exit
elif [ ! "$(which obabel)" ]; then
    echo "openbabel not exist"
    exit
elif [ ! "$(which xtb)" ]; then
    echo "xtb not in your path"
    exit
elif [ ! "$(which mpirun)" ]; then
    echo "openmpi not exist"
    exit
elif [ ! $name ]; then
        echo "please input job name at first place "
        exit
elif [ ! $struDir ]; then
        echo "please input mol dir at second place "
        exit
elif [ ! -d $struDir ]; then
        echo "wrong, structure folder $struDir dont exist"
        exit
elif [ ! -d  $name ]; then
        mkdir $name
        echo "$(date +%Y-%m-%d\ %H:%M:%S) : mkdir $name and job start "
else
        echo "dir exist job start"
fi

cp -r config $name
cp -r $struDir $name/struc
cd $name
sed -i "2s/Chloroform/${solvent^}" config/template.gjf
sed -i "6s/chloroform/$solvent/" config/template_SP.gjf
# sed -i "21s/chcl3/$solvent/" config/settings3.ini
cp config/submit.pbs ./
cp config/nmr.sh ./
qsub -o ${name}.log -e ${name}.log -N $name submit.pbs
