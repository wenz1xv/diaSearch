#!/bin/bash

####################################################################################
#                       Diastereomer Search based on NMR V-0.91
#       1. Enumerate the Diastereomers
#       2. Compute the NMR of each diastereomers
#       3. Compare and calculate the probility of each diastereomers
#
####################################################################################

# perset
inpfile="smiles.txt"
solvent="methanol"

name="$(awk '{print $2}' $inpfile)_NMR"
red='\033[1;31m'
ed='\033[0m'

# environment test
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
elif [ ! -f $inpfile ]; then
        echo -e "${red}smiles.txt doesnt exist, please input smiles of the structure.${ed}"
        : > $inpfile
        exit
elif [ ! "$(cat $inpfile)" ]; then
        echo -e "${red}smiles.txt is empty, please input smiles of the structure.${ed}"
        : > $inpfile
        exit
elif [ ! $name ]; then
        echo -e "${red}please input name at the second column of smiles.txt. ${ed}"
        exit
elif [ ! -d  $name ]; then
        echo "make dir $name and start the job"
        mkdir $name
        mkdir $name/struc
        mkdir $name/confab
else
        echo "dir $name exist, continue the job"
fi
cp $inpfile $name
cp -r config $name
:>$inpfile
cd $name
echo "The solvent is ${solvent}."
echo "Work as mix isomers search mode."
sed -i "2s/Chloroform/${solvent^}/" config/NMR_template.gjf
sed -i "6s/chloroform/$solvent/" config/template_SP.inp
# sed -i "21s/chcl3/$solvent/" config/settings3.ini
cp config/submit_mix.pbs ./
cp config/nmr_mix.sh ./
chmod +x nmr_mix.sh config/molclus/molclus config/molclus/isostat config/molclus/xyz2QC
:>info.log
qsub -o info.log -e info.log -N $name submit_mix.pbs
