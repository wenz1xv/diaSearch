#!/bin/bash

# perset
inpfile="smiles.txt"
smifile='isomers.smi'
name="$(awk '{print $2}' $inpfile)_struc"
 
if [ ! -d  $name ]; then
        mkdir $name
fi
cp $inpfile $name
# cd into the workdir
cd $name

if [ ! -d tmp ]; then
        mkdir tmp
fi

echo "job $name start at $(date +%Y-%m-%d\ %H:%M:%S)"
 
# function to enumerate the confromation
replace(){
        if [[ $1 -le $count ]]; then
                replace $[$1+1] "$2" "$3"
                replace $[$1+1] $(echo $2|sed "s/_/@@/$[$1-$3]") $[$3+1]
        else
                cnt=$[$cnt+1]
                echo -e $(echo $2|sed 's/_/@/g') "\t" ${name}_con_$cnt  >> $smifile
        fi
}
 
# get smi template
if [ ! -f $smifile ] || [ ! "$(cat $smifile)" ]; then
        echo "Getting smi template"
        cnt=0
        : > $smifile
        SMILES=$(awk '{ gsub(/\/|\\/,"/"); print $1}' $inpfile | awk '{ gsub(/@+/,"_"); print $1}')
        count=$(echo $SMILES| tr -cd '_' | wc -c)
        if [[ $count -le 1 ]]; then
                echo 'only one conformation'
                exit
        else
                echo "Here are $count chiral carbon"
        fi
 
        replace 1 "$SMILES" 0
        if [[ $(awk '!x[$1++]' $smifile|wc -l) -ne $cnt ]]; then
                echo 'something wrong in enumerate'
                exit
        else
                echo "Here are $cnt conformations"
        fi
else
        cnt=$(awk '!x[$1++]' $smifile|wc -l)
        echo "smifile exist, Here are $cnt conformations"
fi
 
# start compute nmr using cal_nmr.sh
for ((i=1;i<=$cnt;i++))
do
        awk 'NR=='$i' {print $0}' $smifile > tmp/${i}.smi
        name=$(awk 'NR=='$i' {print $2}' $smifile)
        obabel tmp/${i}.smi -oxyz -O ${name}.xyz --gen3D -h
done
