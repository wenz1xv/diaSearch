#!/bin/bash


inpfile=inp.xyz

:>carbon.xyz
nums=$(awk '/C /{print NR}' $inpfile)
n=1
for i in $nums;
do
        sed "${i}s/C /Si/" $inpfile | sed "2c carbon=$n,$[$i-2]" >> carbon.xyz
        n=$[$n+1]
done

obabel carbon.xyz -O carbon.smi
