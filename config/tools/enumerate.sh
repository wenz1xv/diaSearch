#!/bin/bash

# perset
inpfile="smiles.txt"
failfile="failed.txt"
smifile='isomers.smi'

name="$(awk '{print $2}' $inpfile)_NMR"
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
ed='\033[0m'

if [ ! -f $inpfile ]; then
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
        mkdir $name
        mkdir $name/struc
fi
cp $inpfile $name
:>$inpfile
cd $name

echo -e "${yellow}[$(date +%Y-%m-%d\ %H:%M:%S)]: $name structure enumerate start. ${ed}"
 
# $1 the number of chrial center, $2 the smiles string, $3 nums of center has been replaced
subreplace(){
        if [[ $1 -le $count ]]; then
                subreplace $[$1+1] "$2" "$3"
                subreplace $[$1+1] $(echo $2|sed "s/b/@@/$[$1-$3]") $[$3+1]
        else
                cnt=$[$cnt+1]
                echo "$(echo $2|sed 's/b/@/g') ${name}_$cnt"  >> $smifile
        fi
}

# $1 the smiles string
replace(){
        if [[ "$(echo $1 | grep tC=Ct)" ]]; then
                replace "$(echo $1|sed 's/tC=Ct/\/C=C\\/')"
                replace "$(echo $1|sed 's/tC=Ct/\/C=C\//')"
        elif [[ "$(echo $1 | grep C=Ct)" ]]; then
                replace "$(echo $1|sed 's/C=Ct/C=C\\/')"
                replace "$(echo $1|sed 's/C=Ct/C=C\//')"
        else
                subreplace 1 "$1" 0
        fi
}

# enumerate structure by SMILES format
if [ ! -f $smifile ] || [ ! "$(cat $smifile)" ]; then
        echo -e "${yellow}[$(date +%Y-%m-%d\ %H:%M:%S)]: Getting smi template${ed}"
        cnt=0
        : > $smifile
        SMILES=$(awk '{ gsub(/\/|\\/,"t"); print $1}' $inpfile | awk '{ gsub(/@+/,"b"); print $1}')
        count=$(echo $SMILES| tr -cd 'b' | wc -c)
        if [[ $count -le 1 ]]; then
                echo -e "${yellow}only one conformation${ed}"
                exit
        else
                echo -e "${green}Here are $count chiral carbon, and $(echo $SMILES| tr -cd 't' | wc -c) cis-trans center${ed}"
        fi
        replace "$SMILES"
        if [[ $(awk '!x[$1++]' $smifile|wc -l) -ne $cnt ]]; then
                echo -e "${red}something wrong in enumerate${ed}"
                exit
        else
                echo -e "${green}Here are $cnt conformations${ed}"
        fi
else
        cnt=$(awk '!x[$1++]' $smifile|wc -l)
        echo -e "${green}smifile exist, Here are $cnt conformations${ed}"
fi

echo -e "${yellow}[$(date +%Y-%m-%d\ %H:%M:%S)]: get smiles template finished${ed}"

:>$failfile
for ((i=1;i<=$cnt;i++))
do
        awk 'NR=='$i' {print $0}' $smifile > tmp.smi
        name=$(awk 'NR=='$i' {print $2}' $smifile)
        echo -e "${green}generating ${name}${ed}"
        obabel tmp.smi -oxyz -O struc/${name}.xyz --gen3D -h
        rm tmp.smi
        if [ ! "$(awk '{if($2!=0 && NR>2) x++} END {print x}' struc/${name}.xyz)" ]; then
                echo -e "${red}$i : molecule $name is wrong${ed}"
                awk 'NR=='$i' {print $0}' $smifile >> $failfile
        fi
done

echo -e "${yellow}$(cat $failfile | wc -l) structure wrong${ed}"
echo -e "${yellow}[$(date +%Y-%m-%d\ %H:%M:%S)]: $name structure enumerate finished${ed}"