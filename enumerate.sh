#!/bin/bash

# perset
inpfile="smiles.txt"
failfile="failed.txt"
smifile='isomers.smi'


name="$(awk '{print $2}' $inpfile)_struc"
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
ed='\033[0m'

if [ ! -f $inpfile ]; then
        echo "${red}smiles.txt doesnt exist, please input smiles of the structure.${ed}"
        : > $inpfile
        exit
elif [ ! "$(cat $inpfile)" ]; then
        echo "${red}smiles.txt is empty, please input smiles of the structure.${ed}"
        : > $inpfile
        exit
elif [ ! $name ]; then
        echo "${red}please input name at the second column of smiles.txt. ${ed}"
        exit
elif [ ! -d  $name ]; then
        mkdir $name
        mkdir $name/tmp
fi
cp $inpfile $name
:>$inpfile
cd $name

echo "${green}$(date +%Y-%m-%d\ %H:%M:%S): $name structure enumerate start. ${ed}"
 
# function to enumerate the confromation
replace(){
        if [[ $1 -le $count ]]; then
                replace $[$1+1] "$2" "$3"
                replace $[$1+1] $(echo $2|sed "s/_/@@/$[$1-$3]") $[$3+1]
        else
                cnt=$[$cnt+1]
                echo -e $(echo $2|sed 's/_/@/g') "\t" ${name}_$cnt  >> $smifile
        fi
}
 
# get smi template
if [ ! -f $smifile ] || [ ! "$(cat $smifile)" ]; then
        echo "${green}Getting smi template${ed}"
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
                echo "${red}something wrong in enumerate${ed}"
                exit
        else
                echo "${green}Here are $cnt conformations${ed}"
        fi
else
        cnt=$(awk '!x[$1++]' $smifile|wc -l)
        echo "smifile exist, Here are $cnt conformations"
fi

echo "$(date +%Y-%m-%d\ %H:%M:%S): get smiles template finished"

for ((i=1;i<=$cnt;i++))
do
        awk 'NR=='$i' {print $0}' $smifile > tmp/${i}.smi
        name=$(awk 'NR=='$i' {print $2}' $smifile)
        echo -e "${red}generating ${name}${ed}"
        obabel tmp/${i}.smi -oxyz -O ${name}.xyz --gen3D -h > /dev/null
        if [ ! "$(awk '{if($2!=0 && NR>2) x++} END {print x}' ${name}.xyz)" ]; then
                echo -e "${red}$i : molecule $name is wrong${ed}"
                awk 'NR=='$i' {print $0}' $smifile >> $failfile
        fi
done

echo "$(date +%Y-%m-%d\ %H:%M:%S): $name structure enumerate finished"
echo "$(date +%Y-%m-%d\ %H:%M:%S): $(cat $failfile | wc -l) structure wrong"