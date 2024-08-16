# syntax = docker/dockerfile:experimental
FROM ubuntu:22.04

ARG ASCEND_BASE=/usr/local/Ascend
WORKDIR /home/AscendWork

# 安装系统依赖
RUN sed -i "s@http://.*ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list && \
    apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends gcc g++ make cmake zlib1g zlib1g-dev openssl libsqlite3-dev libssl-dev \
    libffi-dev unzip pciutils net-tools libblas-dev gfortran libblas3 curl python3-dev python3-pip && \
    apt clean && rm -rf /var/lib/apt/lists/*
 

# 推理程序需要使用到底层驱动，底层驱动的运行依赖HwHiAiUser，HwBaseUser，HwDmUser三个用户
# 创建运行推理应用的用户及组，HwHiAiUse，HwDmUser，HwBaseUser的UID与GID分别为1000，1101，1102为例
RUN umask 0022 && \
    groupadd  HwHiAiUser -g 1000 && \
    useradd -d /home/HwHiAiUser -u 1000 -g 1000 -m -s /bin/bash HwHiAiUser && \
    groupadd HwDmUser -g 1101 && \
    useradd -d /home/HwDmUser -u 1101 -g 1101 -m -s /bin/bash HwDmUser && \
    usermod -aG HwDmUser HwHiAiUser && \
    groupadd HwBaseUser -g 1102 && \
    useradd -d /home/HwBaseUser -u 1102 -g 1102 -m -s /bin/bash HwBaseUser && \
    usermod -aG HwBaseUser HwHiAiUser

# copy file
COPY ./data /tmp
COPY ./run.sh ./run.sh
COPY ./requirements.txt /tmp/requirements.txt

# install python requirements
RUN mkdir -p ~/.pip  && \
    echo '[global] \n\
    index-url=http://mirrors.aliyun.com/pypi/simple\n\
    trusted-host=mirrors.aliyun.com' >> ~/.pip/pip.conf && \
    pip3 install pip -U && \
    pip3 install -r /tmp/requirements.txt && \
    rm -rf /root/.cache/pip

# install CANN
RUN export CPU_ARCH=$(uname -m) && \ 
    chmod +x /tmp/Ascend-cann-toolkit_*_linux-${CPU_ARCH}.run && \
    bash /tmp/Ascend-cann-toolkit_*_linux-${CPU_ARCH}.run --quiet --install --install-path=$ASCEND_BASE --install-for-all --force

# install NNAE
RUN CPU_ARCH=$(uname -m) && \ 
    chmod +x /tmp/Ascend-cann-nnae_*_linux-${CPU_ARCH}.run && \
    bash /tmp/Ascend-cann-nnae_*_linux-${CPU_ARCH}.run --quiet --install --install-path=$ASCEND_BASE --install-for-all --force

# other environment
RUN chmod +x /home/AscendWork/run.sh && \        
    chown -R HwHiAiUser:HwHiAiUser /home/AscendWork/ && \
    ln -sf /lib /lib64 && \
    mkdir /var/dmp && \
    mkdir /usr/slog && \
    chown HwHiAiUser:HwHiAiUser /usr/slog && \
    chown HwHiAiUser:HwHiAiUser /var/dmp


# for x86_64
ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libc.so.6
# for aarch64
# ENV LD_PRELOAD=/lib/aarch64-linux-gnu/libc.so.6

# set env for CANN
# copy from /usr/local/Ascend/ascend-toolkit/set_env.sh
ENV ASCEND_TOOLKIT_HOME=/usr/local/Ascend/ascend-toolkit/latest
ENV LD_LIBRARY_PATH=${ASCEND_TOOLKIT_HOME}/lib64:${ASCEND_TOOLKIT_HOME}/lib64/plugin/opskernel:${ASCEND_TOOLKIT_HOME}/lib64/plugin/nnengine:${ASCEND_TOOLKIT_HOME}/opp/built-in/op_impl/ai_core/tbe/op_tiling/lib/linux/$(arch):$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${ASCEND_TOOLKIT_HOME}/tools/aml/lib64:${ASCEND_TOOLKIT_HOME}/tools/aml/lib64/plugin:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${ASCEND_TOOLKIT_HOME}/runtime/lib64/stub:${ASCEND_TOOLKIT_HOME}/runtime/lib64:$LD_LIBRARY_PATH
ENV PYTHONPATH=${ASCEND_TOOLKIT_HOME}/python/site-packages:${ASCEND_TOOLKIT_HOME}/opp/built-in/op_impl/ai_core/tbe:$PYTHONPATH
ENV PATH=${ASCEND_TOOLKIT_HOME}/bin:${ASCEND_TOOLKIT_HOME}/compiler/ccec_compiler/bin:${ASCEND_TOOLKIT_HOME}/tools/ccec_compiler/bin:$PATH
ENV ASCEND_AICPU_PATH=${ASCEND_TOOLKIT_HOME}
ENV ASCEND_OPP_PATH=${ASCEND_TOOLKIT_HOME}/opp
ENV TOOLCHAIN_HOME=${ASCEND_TOOLKIT_HOME}/toolkit
ENV ASCEND_HOME_PATH=${ASCEND_TOOLKIT_HOME}


# set env for NNAE
# run source /usr/local/Ascend/nnal/atb/set_env.sh
USER 1000
CMD bash /home/AscendWork/run.sh