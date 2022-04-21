#!/bin/bash


inpfile=inp.xyz
outfile=carbon.smi

:>tmp.xyz
nums=$(awk '/C /{print NR}' $inpfile)
for i in $nums;
do
        sed "${i}s/C /Si/" $inpfile | sed "2c carbon=$[$i-2]" >> tmp.xyz
done
# awk '{ if($1=="C"){sub(/C /,"C"x++" ")}; print}'  inp.xyz

obabel tmp.xyz -O $outfile
rm tmp.xyz
