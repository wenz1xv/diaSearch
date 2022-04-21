#!/bin/bash

inpfile="inp.txt"
outfile="out.txt"
line=$(awk 'NR==1{print NF}' $inpfile)

:>$outfile
for ((i=2;i<=$line;i++))
do
        awk '{print $'$i'}' $inpfile | xargs | sed 's/ /,/g' >> $outfile
done
cat $outfile
