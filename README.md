# 通过NMR计算确定非对映异构体 V1.0 / Determination of Diastereomers by NMR Computation Script V 1.0
 
## 运行流程 / Workflow

### 枚举构型 / Enumerate Isomers

用Open Babel与SMILES格式枚举构型，生成isomers.smi，包含枚举的构型。若枚举构型出错，也可手动枚举到相应目录内。

尝试使用过openbabel 2.3.1、2.4.1、3.1.0 三个版本。
- 2.3.1生成3D结构功能较稳定，但没有confab功能；
- 2.4.1有confab功能，但生成3D结构频繁出错；
- 3.1.0/1版本部分情况下结构生成会出错，但可以通过先生成2D结构，再生成3D结构来避免，同时具有confab功能，最终采用这个版本。

> 此外，还尝试过marvin的molconvert工具进行分子生成，同样会遇到问题，直接使用openbabel即可

### 搜索构象与优化 / Conformation Search and Optimize

对Isomer.smi中每个构型生成构象并进行优化

master分支采用此方法，用xtb进行模拟，部分长链化合物可能出现错误，采用系统搜索可以避免

#### 分子动力学模拟

参见：http://bbs.keinsci.com/thread-16255-1-1.html


#### 系统搜索

见gentor分支

### 计算NMR并根据玻尔兹曼分布加权 / Compute NMR and Weighted by Boltzmann Distribution

默认NMR计算采用B3LYP/6-31G\*\*，Boltzmann分布为298.15K下

#### 泛函与基组的选择

泛函选择常用的B3LYP或B972即可；

pcSseg系列是专门设计用于计算NMR的基组，但Gaussian16并没有内置；

def2TZVP是很大的基组，计算十分耗时，理论上精度也会更高。

### 根据贝叶斯概率计算各构型分数 / Compute the Probility of each Diastereomer

这部分功能依赖于python3 的scipy与numpy，如无必要可以在EXCEL中计算，在tools中的calp.py实现

## 依赖程序 / Requirement
- gaussian
- orca
- xtb
- open babel
- python scipy numpy (optional)
 
## 环境变量 / Environment
- g16
- XTBPATH
- Openmpi Path
- ORCA_PATH
- Openbabel Path

### 环境变量示例 / Environment Example

```
# 你的 ~/.bashrc 应包含以下内容
# Your ~/.bashrc should contain the following settings

# Gaussian 16 path 
export g16root=$HOME/opt/gaussian 
export GAUSS_EXEDIR=$g16root/g16 
export GAUSS_SCRDIR=$g16root/scr 
source $g16root/g16/bsd/g16.profile 
export GAUSS_SCRDIR=$HOME/temp 
 
# xtb path 
export XTBPATH=$HOME/opt/xtb_6.3.2/share/xtb 
export PATH=$HOME/opt/xtb_6.3.2/bin:$PATH 
export PATH=$HOME/opt/crest/bin:$PATH 
 
# openmpi path 
export PATH=$HOME/opt/openmpi_4.0.4/bin:$PATH 
export LD_LIBRARY_PATH=$HOME/opt/openmpi_4.0.4/lib:$LD_LIBRARY_PATH 
 
# ocra path 
export PATH=$HOME/opt/orca_4.2.1:$PATH 
export ORCA_PATH=$HOME/opt/orca_4.2.1 
export LD_LIBRARY_PATH=$HOME/opt/orca_4.2.1:$LD_LIBRARY_PATH 
 
# openbabel path 
export PATH=$HOME/opt/openbabel-3.1.1/bin:$PATH 
export BABEL_DATADIR=$HOME/opt/openbabel-3.1.1/share/openbabel/3.1.0 
export BABEL_LIBDIR=$HOME/opt/openbabel-3.1.1/lib/openbabel/3.1.0 
export LD_LIBRARY_PATH=$HOME/opt/openbabel-3.1.1/lib:$LD_LIBRARY_PATH 
```
 
## 文件目录 / File Directory

```
- run.sh  # 自动运行脚本，基于 Torque/PBS 作业管理系统
- smiles.txt # 输入分子文件
- config/
    - cal_nmr.sh # 构象搜索与NMR计算脚本
    - TMS.xyz # 标准物质TMS结构
    - template.gjf # NMR计算时模板文件
    - md.inp and settings{n}.ini # 构象搜索与优化配置文件
    - inp{n}.txt # isostat等交互输入
    - molclus/ #  molclus程序文件夹
```

## 输入与输出 / Input & output

### 输入

输入格式为SMILES格式的分子，需要从ChemDraw 3D中输出，包含顺反异构与手性信息，否则不进行枚举。

```
#smiles.txt
SMILES_STRINGS  NAME
```

### 输出

工作目录为 输入中名字_NMR

在工作目录下：

- CNMR.txt  碳谱信息，可直接用在calp中调用
- HNMR.txt  氢谱信息
- isomers.xyz   枚举的构象，SMILES格式
- failed.txt    生成3D结构失败的构型
- carbon.smi    按碳顺序，将分子中的碳依次替换为硅，用于确定碳排序
- structure.txt 构象搜索完毕后转换为SMILES的文件，用于验证构象搜索是否发生变化 
- info.log  输出信息
 
## 参考文献/ Citation
[1] Smith S G, Goodman J M. Assigning stereochemistry to single diastereoisomers by GIAO NMR calculation: The DP4 probability[J]. Journal of the American Chemical Society, 2010, 132(37): 12946-12959.

[2] Neese F. Software update: the ORCA program system, version 4.0[J]. Wiley Interdisciplinary Reviews: Computational Molecular Science, 2018, 8(1): e1327.

[3] O'Boyle N M, Banck M, James C A, et al. Open Babel: An open chemical toolbox[J]. Journal of cheminformatics, 2011, 3(1): 1-14.

[4] Pracht P, Caldeweyher E, Ehlert S, et al. A robust non-self-consistent tight-binding quantum chemistry method for large molecules[J]. 2019.

[5] Tian Lu, molclus program, Version 1.9.2, http://www.keinsci.com/research/molclus.html

[6] FRISCH M J, TRUCKS G W, SCHLEGEL H B, et al. Gaussian 16 Rev. C.01 [Z]. Wallingford, CT. 2016