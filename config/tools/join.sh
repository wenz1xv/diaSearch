#!/bin/bash
# perset
cnmrfile='CNMR.txt'
hnmrfile='HNMR.txt'
smifile='isomers.smi'

# cd into the workdir
cnt=$(awk '!x[$1++]' $smifile|wc -l)

# start compute nmr using cal_nmr.sh
:>$cnmrfile
:>$hnmrfile
:>order.txt
for dirname in $(ls | grep _NMR_);
do
        awk '{print $2}' ${dirname}/CNMR.txt | xargs | sed 's/ /,/g' >> $cnmrfile
        awk '{print $2}' ${dirname}/HNMR.txt | xargs | sed 's/ /,/g'  >> $hnmrfile
        echo $dirname >> order.txt
done
