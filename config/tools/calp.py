import numpy as np
import math
from scipy import stats

def get_t(delta_exp, delta_cal):
    n = len(delta_exp)
    slope, intercept, r_2, p, std_err = stats.linregress(delta_exp, delta_cal)
    err1 = np.array([(x - intercept) / slope for x in delta_cal]) - delta_exp
    err2 = np.array([ x * slope + intercept for x in delta_exp]) - delta_cal
    #d = delta_cal-delta_exp
    s1 = np.var(err1)
    s2 = np.var(err2)
    #sd = np.var(d)
    v = (n-1)*((s1+s2)**2)/(s1**2+s2**2)
    sigma = math.sqrt((s1+s2)/n)
    dpsigma = 1.557
    dpv = 6.227
    ti = 1
    dpt = 1
    for i in range(n):
#         z = abs(delta_cal[i]-slope*delta_exp[i]-intercept)/(slope * sigma)
        z = (abs(err2[i])+abs(err1[i]))/2
        ti = ti * (1 - stats.t.cdf(z/sigma, v))
#         dpz = abs(delta_cal[i]-slope*delta_exp[i]-intercept)/(slope * dpsigma)
        dpz = abs(err1[i])
        dpt = dpt * (1 - stats.t.cdf(dpz/dpsigma, dpv))
    return ti, dpt, r_2

def get_p(delta_exp, delta_cals):
    n = len(delta_cals)
    ts = []
    dps = []
    r = []
    for i in range(n):
        ti, dpt, ri = get_t(delta_exp, delta_cals[i])
        ts.append(ti)
        dps.append(dpt)
        r.append(ri)
    p = [t/np.sum(ts) for t in ts]
    dp = [t/np.sum(dps) for t in dps]
    return np.around(np.array(p), 4), np.around(np.array(dp), 4), np.around(np.array(r), 5)

def assign_ppm(delta_exp, delta_cals):
    pass

def read_data(filename):
    data = []
    with open(filename, 'r') as file:
        line = file.readline().strip()
        while line:
            data.append(list(map(float, line.split(","))))
            line = file.readline().strip()
    return np.array(data)

if __name__ == '__main__':
#     np.set_printoptions(precision=6)
    delta_exps = read_data("exp_nmr.txt")
    delta_cals = read_data("CNMR.txt")
    p, dp, r = get_p(delta_exps[0], delta_cals)
    with open("result.txt", "w") as nfile:
        nfile.write("SMILES\tr2\tDP4probility\tBayes\n")
    with open("isomers.smi","r") as file:
        lines = file.readlines()
        for i in range(len(lines)):
            with open("result.txt", "a+") as nfile:
                nfile.write(lines[i].split(' ')[0])
                nfile.write("\t%.5f\t%.4f\t%.4f\n" %(r[i], dp[i], p[i]) )
