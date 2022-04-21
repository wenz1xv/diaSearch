#!/bin/bash
# perset
inpfile="smiles.txt"
tmpdir='tmp'
nmrfile='nmr.txt'
smifile='con.smi'
name=$(awk '{print $2}' $inpfile)

# cd into the workdir
cd $name
if [ ! -d $tmpdir ]; then
        mkdir $tmpdir
fi
cnt=$(awk '!x[$1++]' $smifile|wc -l)

# start compute nmr using cal_nmr.sh
for ((i=1;i<=$cnt;i++))
do
        awk 'NR=='$i' {print $0}' $smifile > ${tmpdir}/tmp.smi
        dirname=$(awk 'NR=='$i' {print $2}' $smifile)
#       obabel ${tmpdir}/tmp.smi -O inp.xyz --gen3D -h
#       ./cal_nmr.sh
        if [[ $i -eq 1 ]]; then
                cp ${dirname}/nmr_result.txt $nmrfile
        else
                cp $nmrfile ${tmpdir}/nmr.txt
                join ${tmpdir}/nmr.txt ${dirname}/nmr_result.txt > $nmrfile
        fi
done
cd ..
cp $name/con.smi ${name}.out
cat $name/nmr.txt >> ${name}.out
