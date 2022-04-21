# 本文档已过时，待补充

# 构型NMR计算搜索自动化脚本 / Isomer NMR Compute Script
 
## 运行流程 / Workflow

### 枚举构型 / Enumerate Isomers
用Open Babel与SMILES格式枚举构型，生成Isomer.smi

> Open babel 在生成3D构构象时容易出错！不同版本的open babel存在各自特性，经测试至少3.0.0以上版本能较稳定运行，否则在复杂构型中手性碳会出错！

### 搜索构象并优化 / Conformation Search and Optimize
对Isomer.smi中每个构型生成构象并进行优化

参见：http://bbs.keinsci.com/thread-16255-1-1.html

### 计算NMR并根据玻尔兹曼分布加权 / Compute NMR and Weighted by Boltzmann Distribution
默认NMR计算采用B3LYP/6-31G\*，Boltzmann分布为298.15K下由Isostat计算
> 对于绝对构型不同的两个相对构型相同的异构体而言，其CNMR应该是接近的，因此在保证计算方法准确的情况下，可以减少一半的计算量。

> 此处存在问题：小体系(手性碳小于3个)时，简单的基组(6-31G\*)与复杂体系(def2-TZVP)不存在太大的差别，用于构型确定足够。但在复杂体系中(3个以上手性碳)，简单体系的计算方法不足以满足精度要求，出现两个相对构型NMR有较大出入的情况，应该换用复杂体系，或pcSseg-1尝试。此外，在ppm较大处的计算值会比实验值更小，在ppm较小处与实验值符合较好，对于CNMR中化学位移较大的C，偏差同样较大，因此简单的线性拟合可能不足以给不同构型的CNMR计算值打分，需要参考DP4-AI的计算方法。

#### 根据讨论，在小体系中对映异构体CNMR接近，复杂体系中并不接近，尤其计算方法中不尽相同，因此误差存在合理。

### 根据贝叶斯概率计算各构型分数 / Compute the Probility of each Diastereomer
> 这部分功能依赖于python3 的scipy与numpy，如无必要可以在EXCEL中计算

> 程序生成的NMR标号根据xyz文件顺序，与常规序号迥异，暂无解决办法

具体计算推导待补充...


## 依赖程序 / Requirement
- gaussian
- orca
- xtb
- open babel
- \*python scipy numpy 
 
## 环境变量 / Environment
- g16
- XTBPATH
- Openmpi Path
- ORCA_PATH
- Openbabel Path


### 示例 / Example
```
# 你的 ~/.bashrc 应包含以下内容
# Your ~/.bashrc should contain the following settings

# Gaussian Path
export g16root=$HOME/opt/gaussian
export GAUSS_EXEDIR=$g16root/g16
export GAUSS_SCRDIR=$g16root/scr
source $g16root/g16/bsd/g16.profile
export GAUSS_SCRDIR=$HOME/temp

# XTB Path
export XTBPATH=$HOME/opt/xtb-6.3.2/share/xtb
export PATH=$HOME/opt/xtb-6.3.2/bin:$PATH
export OMP_NUM_THREADS=12
export MKL_NUM_THREADS=12
export OMP_STACKSIZE=1000m
ulimit -s unlimited

# Openmpi Path
export PATH=$HOME/opt/openmpi-4.0.4/bin:$PATH
export LD_LIBRARY_PATH=$HOME/opt/openmpi-4.0.4/lib:$LD_LIBRARY_PATH

# ORCA Path
export ORCA_PATH=$HOME/opt/orca-4.2.1
export PATH=$ORCA_PATH:$PATH
export LD_LIBRARY_PATH=$ORCA_PATH:$LD_LIBRARY_PATH
alias orca="$ORCA_PATH/orca"

# Openbabel Path
export PATH=$HOME/opt/openbabel/bin:$PATH
export BABEL_DATADIR=$HOME/opt/openbabel/share/openbabel/2.3.1
```
 
## 文件目录 / File Directory
```
- search.sh  # 构型搜索与计算脚本 / Isomer search and compute script
- submit.pbs # PBS 作业系统提交文件 / Protable Batch System job submit file
# 示例代码 / Example Code: qsub -o yourname.log -e yourname.log submit.pbs
- smiles.txt # 输入分子文件 / The molecule input file
#格式 / Format : SMILES_STRINGS NAME
- config/
    - cal_nmr.sh # 构象搜索与NMR计算脚本
    - TMS.xyz # 标准物质TMS结构
    - template.gjf # NMR计算时模板文件
    - md.inp and settings{n}.ini # 构象搜索与优化配置文件
    - inp{n}.txt # isostat等交互输入
    - molclus/ #  molclus程序文件夹
```

## 结果与日志 / Result and the log

输出中包含：SMILES格式的构型结构、CNMR、HNMR

The output will include the structure of each isomer in the format of SMILES, CNMR, HNMR

输出将被保存在当前目录下的$name.out

The output file is $name.out in the current folder

日志将被保存在当前目录下的$name.log

The log file is $name.log in the current folder
 
 
## 参考文献/ Citation
[1] Smith S G, Goodman J M. Assigning stereochemistry to single diastereoisomers by GIAO NMR calculation: The DP4 probability[J]. Journal of the American Chemical Society, 2010, 132(37): 12946-12959.

[2] Neese F. Software update: the ORCA program system, version 4.0[J]. Wiley Interdisciplinary Reviews: Computational Molecular Science, 2018, 8(1): e1327.

[3] O'Boyle N M, Banck M, James C A, et al. Open Babel: An open chemical toolbox[J]. Journal of cheminformatics, 2011, 3(1): 1-14.

[4] Pracht P, Caldeweyher E, Ehlert S, et al. A robust non-self-consistent tight-binding quantum chemistry method for large molecules[J]. 2019.

[5] Tian Lu, molclus program, Version 1.9.2, http://www.keinsci.com/research/molclus.html

[6] FRISCH M J, TRUCKS G W, SCHLEGEL H B, et al. Gaussian 16 Rev. C.01 [Z]. Wallingford, CT. 2016