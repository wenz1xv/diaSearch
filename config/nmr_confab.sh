#!/bin/bash

maxCount=8
energy_threshold=3
root=$(pwd)
dirname=$(awk 'NR==2{print $1}' inp.xyz)
workDir=$(pwd)/$dirname 
echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: start $dirname NMR cal"
if [ -d $dirname ]; then
	echo "workDir $dirname exist"
else
    echo "mkdir $dirname"
	mkdir $dirname
	mkdir $workDir/logs
	cp inp.xyz $dirname # copy the input file to work dir
fi

cp -r $root/config/molclus $workDir/

# Step 0 Conformation Search using confab, done by enumerate
# Step 1 Conformation Optimization using molclus with xtb GFN0-xTB
cd $workDir
if  [ ! "$(cat inp.xyz)" ]; then
	echo "step 0 got wrong !"
	exit
elif [ -f step1.xyz ] && [ "$(cat step1.xyz)" ]; then
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 1 has been done"
else
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 1 start"
	cp inp.xyz molclus/traj.xyz
	cd molclus
	cp $root/config/settings2.ini settings.ini
	./molclus > $workDir/logs/step1_molclus.log
    cp isomers.xyz $workDir/step1_isomers.xyz
	./isostat isomers.xyz -Gdis 0.5 -Edis 0.5 -T 298.15 > $workDir/logs/step1_isostat.log
	mv cluster.xyz $workDir/step1.xyz
	rm traj.xyz
fi

# Step 2 Conformation Optimization using molclus with xtb GFN2-xTB
cd $workDir
if  [ ! "$(cat step1.xyz)" ]; then
	echo "step 1 got wrong !"
	exit
elif [ -f step2.xyz ] && [ "$(cat step2.xyz)" ]; then
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 2 has been done"
else
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 2 start"
	cp step1.xyz molclus/traj.xyz
	cd molclus
	cp $root/config/settings3.ini settings.ini
	./molclus > $workDir/logs/step2_molclus.log
    cp isomers.xyz $workDir/step2_isomers.xyz
	./isostat isomers.xyz -Gdis 0.5 -Edis 0.5 -T 298.15 > $workDir/logs/step2_isostat.log
	mv cluster.xyz $workDir/step2.xyz
	rm traj.xyz
fi

# Step 3 Conformation Optimization using molclus with Gaussian & ORCA
cd $workDir
if  [ ! "$(cat step2.xyz)" ]; then
	echo "step 2 got wrong !"
	exit
elif [ -f final.xyz ] && [ "$(cat final.xyz)" ]; then
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 3 has been done"
else
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: step 3 start"
	cp step2.xyz molclus/traj.xyz
	cd molclus
	cp $root/config/settings4.ini settings.ini
	cp $root/config/template_SP.inp ./
	nums=$(awk '/DE/' $workDir/logs/step2_isostat.log |awk '$11<'$energy_threshold'' |wc -l)
	if [[ $nums -gt $maxCount ]]; then
		nums=$maxCount
	fi
	echo ${nums}' structure remain'
	sed -i '2,2s/ngeom= 0/ngeom= '$nums'/g' settings.ini
	./molclus > $workDir/logs/step3_molclus.log
    cp isomers.xyz $workDir/step3_isomers.xyz
	./isostat isomers.xyz -Gdis 0.5 -Edis 0.5 -T 298.15 > $workDir/logs/step3_isostat.log
	awk '/Ratio/' $workDir/logs/step3_isostat.log > $workDir/ratio.txt
	mv cluster.xyz $workDir/final.xyz
	rm traj.xyz
fi


# get the smiles of conformation to sure the diastereomers
cd $workDir
if  [ ! "$(cat final.xyz)" ]; then
	echo "step 3 got wrong !"
	exit
elif [ ! -f logs/structure.smi ]; then
    obabel final.xyz -osmi | uniq> logs/structure.smi
fi

cat logs/structure.smi

# caculate TMS nmr with Gaussian
cd $workDir
if [ -f $root/TMS.out ] && [ "$(cat $root/TMS.out)" ]; then
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: TMS out exist"
    cp $root/TMS.out $workDir
else
    if [ -f TMS.xyz ] && [ "$(cat TMS.xyz)" ]; then
	    echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: TMS xyz exist"
    else
	    echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: compute TMS structure"
    	cp $root/config/TMS.xyz $workDir/molclus/traj.xyz
	    cp $root/config/settings4.ini $workDir/molclus/settings.ini
    	sed -i '2,2s/ngeom= 0/ngeom= 1/g' $workDir/molclus/settings.ini
	    cd $workDir/molclus
    	./molclus > $workDir/logs/tms.log
	    ./isostat isomers.xyz -Gdis 0.5 -Edis 0.5 -T 298.15 > $workDir/logs/tms.log
    	mv cluster.xyz $workDir/TMS.xyz
    fi
    cd $workDir
	echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: compute TMS NMR"
	cp $root/config/NMR_template.gjf ./template.gjf
	$workDir/molclus/xyz2QC < $root/config/inp1.txt > /dev/null
	g16 Gaussian.gjf $workDir/TMS.out
fi

Ciso=$(awk '/C.*Isotropic/ {sum+=$5; base+=1} END {print sum/base}' TMS.out)
Hiso=$(awk '/H.*Isotropic/ {sum+=$5; base+=1} END {print sum/base}' TMS.out)
echo $Ciso > $workDir/logs/CNMR.log
echo $Hiso > $workDir/logs/HNMR.log

# compute target nmr
cd $workDir
if [ -f target.out ] && [ "$(cat target.out)" ]; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: Target NMR exist"
else
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: compute target NMR"
        cp $root/config/NMR_template.gjf ./template.gjf
        $workDir/molclus/xyz2QC < $root/config/inp2.txt > /dev/null
        g16 Gaussian.gjf $workDir/target.out
fi
rm *.gjf
awk '/ C .*Isotropic|NMR.*\\/{if($5 ~ /^[0-9.-]+$/){print $0 "   ppm = " base-$5;} else {print $0;}}' base=$Ciso $workDir/target.out >> $workDir/logs/CNMR.log
awk '/ H .*Isotropic|NMR.*\\/{if($5 ~ /^[0-9.-]+$/){print $0 "   ppm = " base-$5;} else {print $0;}}' base=$Hiso $workDir/target.out >> $workDir/logs/HNMR.log

# combine the NMR by Boltzmann Distribution
echo "name $(awk 'NR==2{print $1}' inp.xyz)" > nmr_result.txt

cd $workDir
echo "CNMR" >> nmr_result.txt
: > CNMR.txt
for Cindex in $(awk '{if(!x[$1]++ && $1 ~ /^[0-9]+$/) print $1}' logs/CNMR.log);
do
        percent=$(awk '{gsub(/%/, "");print $6}' ratio.txt| xargs| sed 's/ /,/g')
        sum=$(awk '/ '$Cindex' /' logs/CNMR.log | awk -v arr=$percent 'BEGIN{split(arr,percent,",")} {sum+=$11*0.01*percent[NR]} END{print sum}');
        echo $Cindex $sum >> nmr_result.txt
        echo $Cindex $sum >> CNMR.txt
done

echo "HNMR" >> nmr_result.txt
: > HNMR.txt
for Hindex in $(awk '{if(!x[$1]++ && $1 ~ /^[0-9]+$/) print $1}' logs/HNMR.log);
do
        percent=$(awk '{gsub(/%/, "");print $6}' ratio.txt| xargs| sed 's/ /,/g')
        sum=$(awk '/ '$Hindex' /' logs/HNMR.log | awk -v arr=$percent 'BEGIN{split(arr,percent,",")} {sum+=$11*0.01*percent[NR]} END{print sum}');
        echo $Hindex $sum >> nmr_result.txt
        echo $Hindex $sum >> HNMR.txt
done

echo "[$(date +%Y-%m-%d\ %H:%M:%S)]: finish job $dirname"
