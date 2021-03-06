#!/bin/bash


workdir=$1
enu=${2:-'2'}
if [ ! "$workdir" ]; then
        echo 'please input workdir at first place'
        exit
fi

cd $workdir

inpfile='smiles.txt'
failfile='failed.txt'
smifile='isomers.smi'
carbonfile='carbon.smi'

name="$(awk '{print $2}' $inpfile)_NMR"

echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: $name structure enumerate start."
 
# $1 the number of chrial center, $2 the smiles string, $3 nums of center has been replaced
subreplace(){
        if [[ $1 -le $count ]]; then
                subreplace $[$1+1] "$2" "$3"
                subreplace $[$1+1] $(echo $2|sed "s/b/@@/$[$1-$3]") $[$3+1]
        else
                cnt=$[$cnt+1]
                echo "$(echo $2|sed 's/b/@/g') ${name}_$(echo $cnt | awk '{printf("%03d\n",$0)}')"  >> $smifile
        fi
}

# $1 the smiles string
replace(){
        if [[ "$(echo $1 | grep t.=.t)" ]]; then
                replace "$(echo $1|sed 's/t\(.\)=\(.\)t/\/\1=\2\\/')"
                replace "$(echo $1|sed 's/t\(.\)=\(.\)t/\/\1=\2\//')"
        elif [[ "$(echo $1 | grep t)" ]]; then
                replace "$(echo $1|sed 's/t/\\/')"
                replace "$(echo $1|sed 's/t/\//')"
        else
                subreplace 1 "$1" 0
        fi
}

# enumerate structure by SMILES format
if [  -f $smifile ] && [ "$(cat $smifile)" ]; then
        cnt=$(awk '!x[$1++]' $smifile|wc -l)
        echo "smifile exist, Here are $cnt conformations"
else
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: Getting smi template"
        cnt=0
        : > $smifile
        if [ "$enu" -eq "1" ]; then
                SMILES=$(awk '{ gsub(/\/|\\/,"t"); print $1}' $inpfile | awk '{ gsub(/@+/,"b"); print $1}')
                count=$(echo $SMILES| tr -cd 'b' | wc -c)
                count1=$(echo $SMILES| tr -cd 't' | wc -c)
                if [[ $count -le 1 ]] && [[ $count1 -le 1 ]] ; then
                        echo "Only one conformation"
                        exit
                else
                        echo "Here are $count chiral carbon, and $count1 cis-trans center"
                fi
                replace "$SMILES"
        elif [ "$enu" -eq "2" ]; then
                SMILES=$(awk '{ gsub(/@+/,"b"); print $1}' $inpfile)
                count=$(echo $SMILES| tr -cd 'b' | wc -c)
                if [[ $count -le 1 ]]; then
                        echo "Only one conformation"
                        exit
                else
                        echo "Here are $count chiral carbon."
                fi
                subreplace 1 "$SMILES" 0
        else
                echo "Wrong enu mode"
                exit
        fi

        if [[ $(awk '!x[$1++]' $smifile|wc -l) -ne $cnt ]]; then
                echo "Something wrong in enumerate"
                exit
        else
                echo "Here are $cnt conformations"
        fi
fi

echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: get smiles template finished"

:>$failfile
for ((i=1;i<=$cnt;i++))
do
        awk 'NR=='$i' {print $0}' $smifile > tmp.smi
        mol=$(awk 'NR=='$i' {print $2}' $smifile)
        echo "Generating ${mol}"
        if [ -f struc/${mol}.xyz ] && [ "$(awk '{if($2!=0 && NR>2) x++} END {print x}' struc/${mol}.xyz)"  ]; then
                echo "mol $mol exist"
        else
                obabel tmp.smi -omol -O tmp.mol --gen2D -h
                obabel tmp.mol -oxyz -O struc/${mol}.xyz --gen3D
        fi
        rm tmp.smi tmp.mol
        if [ ! "$(awk '{if($2!=0 && NR>2) x++} END {print x}' struc/${mol}.xyz)" ]; then
                echo "$i : molecule $mol is wrong$"
                awk 'NR=='$i' {print $0}' $smifile >> $failfile
        fi
done

echo "$(cat $failfile | wc -l) structure wrong"
echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: $name structure enumerate finished"

echo "generate carbon file"

if [ -f $carbonfile ] && [ "$(cat $carbonfile)" ]; then
        echo "carbon file $carbonfile exist"
else
        :>tmp.xyz
        nums=$(awk '/C /{print NR}' struc/${mol}.xyz)
        for i in $nums;
        do
                sed "${i}s/C /Si/" struc/${mol}.xyz | sed "2c carbon=$[$i-2]" >> tmp.xyz
        done
        obabel tmp.xyz -O $carbonfile
        rm tmp.xyz
fi

