#!/bin/bash

soc_version=310b # support 310b, 310p, 910, 910b
cann_version=8.0.RC2
cpu_arch=$(uname -m)

# create data dir
if [ ! -d "data" ]; then
    mkdir data
fi

# ==========check file exist =================
# check Ascend-cann-toolkit_${cann_version}_linux-${cpu_arch}.run
cann_toolkit_file="data/Ascend-cann-toolkit_${cann_version}_linux-${cpu_arch}.run"
# if file not exist
if [ -f ${cann_toolkit_file} ]; then
    echo "find ${cann_toolkit_file}"
else
    echo "please put ${cann_toolkit_file} here"
    echo "download from https://www.hiascend.com/developer/download/community/result?module=cann&product=1&model=20"
    echo "exit, Bye!"
    exit 1
fi

# check Ascend-cann-kernels-${soc_version}_${cann_version}_linux.run
cann_kernel_file="data/Ascend-cann-kernels-${soc_version}_${cann_version}_linux.run"
if [ -f ${cann_kernel_file} ]; then
    echo "find ${cann_kernel_file}"
else
    echo "please put ${cann_kernel_file} here"
    echo "download from https://www.hiascend.com/developer/download/community/result?module=cann&product=1&model=20"
    echo "exit, Bye!"
    exit 1
fi

# check Ascend-cann-nnae_${cann_version}_linux-${cpu_arch}.run
cann_nnae_file="data/Ascend-cann-nnae_${cann_version}_linux-${cpu_arch}.run"
if [ -f ${cann_nnae_file} ]; then
    echo "find ${cann_nnae_file}"
else
    echo "please put ${cann_nnae_file} here"
    echo "download from https://www.hiascend.com/developer/download/community/result?module=cann&product=1&model=20"
    echo "exit, Bye!"
    exit 1
fi

docker build -t ascend-${soc_version}:${cann_version}-${cpu_arch} . -f Dockerfile
