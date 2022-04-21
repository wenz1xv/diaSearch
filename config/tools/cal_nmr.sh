#!/bin/bash

# environment test
dirname=$1
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
elif [ ! $dirname ]; then
        echo "please input mol dir as paramater"
        exit
elif [ ! -d $dirname ]; then
        echo "wrong, structure folder $dirname dont exist"
        exit
else
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] : NMR job start "
fi

cp -r config $dirname
cd $dirname
sed -i "2s/Chloroform/${solvent^}" config/template.gjf
sed -i "6s/chloroform/$solvent/" config/template_SP.gjf
# sed -i "21s/chcl3/$solvent/" config/settings3.ini
cp config/submit.pbs ./
cp config/nmr.sh ./
chmod +x nmr.sh config/molclus/molclus config/molclus/isostat config/molclus/xyz2QC
qsub -o ${dirname}.log -e ${dirname}.log -N $dirname submit.pbs