#!/bin/bash


inpfile=inp.xyz
outfile=hydrogen.smi

:>hydrogen.xyz
nums=$(awk '/H /{print NR}' $inpfile)
n=1
for i in $nums;
do
        sed "${i}s/H /Li /" $inpfile | sed "2c hydrogen=$n,$[$i-2]" >> hydrogen.xyz
        n=$[$n+1]
done

obabel hydrogen.xyz -O $outfile
