# 简介
1. 昇腾推理基础镜像，基于ubuntu22.04制作，内部集成推理通用的第三方库（系统包、pip）和TOOLKIT推理引擎。
2. 主要用途，模拟昇腾cpu运行环境，执行atc命令转换模型结构。因为开发板上面的cpu性能较差，我们可以在性能较好的x86_64的Linux系统上面使用docker镜像来执行该操作。
3. 参考了官方的docker构建项目：[gitee地址](https://gitee.com/ascend/ascend-docker-image/tree/dev/ascend-infer-310b)

### 编译docker
1. 根据你要模拟的昇腾芯片，修改build.sh中的`soc_version`(该参数决定昇腾芯片型号)和`cann_version`(该参数决定CANN开发工具的版本)。目前参数默认值如下所示：
| soc_version                          | cann_version     |
| ------------------------------------ | ---------------- |
| 310b (可选值：310b, 310p, 910, 910b) | 8.0.RC2 |

2. 该容器编译后的.om模型最终还是需要在昇腾设备上面运行，所以请确保昇腾设备上面安装的CANN版本和该容器的CANN版本一致，这点非常重要。

3. 根据你上面定的参数值，去官方下载对应的文件。[下载地址](https://www.hiascend.com/developer/download/community/result?module=cann&cann=8.0.RC2.beta1&product=1&model=20)，以容器即将运行的平台x86_64为例，我们需要下载下面3个文件，并存放在data目录中。
  ```bash
  Ascend-cann-toolkit_8.0.RC2_linux-x86_64.run
  Ascend-cann-nnae_8.0.RC2_linux-x86_64.run
  Ascend-cann-kernels-310b_8.0.RC2_linux.run
  ```

4. 运行下面的命令，检查一下三个文件是否完整。提示`SHA256 checksums are OK. All good.`则说明没啥问题。
  ```bash
  # 进入目录
  cd data

  # 授予可执行权限
  chmod +x ./Ascend-cann-toolkit_8.0.RC2_linux-x86_64.run
  chmod +x ./Ascend-cann-nnae_8.0.RC2_linux-x86_64.run
  chmod +x ./Ascend-cann-kernels-310b_8.0.RC2_linux.run

  # 分别检查
  ./Ascend-cann-toolkit_8.0.RC2_linux-x86_64.run --check
  ./Ascend-cann-nnae_8.0.RC2_linux-x86_64.run --check
  ./Ascend-cann-kernels-310b_8.0.RC2_linux.run --check

  # 返回上层目录
  cd ..
  ```

5. 运行build.sh，开始编译docker镜像。编译成功后，可以得到一个docker镜像：`ascend-310b:8.0.RC2-x86_64`。
6. 运行docker镜像，可以使用下面的命令来简单测试一下。
  ```bash
  docker run -it --name ascend ascend-310b:8.0.RC2-x86_64 /bin/bash
  ```

7. 在容器内，输入下面的命令简单测试一下atc命令，没报错说明则说明是正常的。
  ```bash
  atc --help
  ```

8. 如果还需要做进一步测试，可以拿官方的demo来测试一下atc转onnx为om的能力。[项目地址](https://gitee.com/ascend/samples/tree/master/inference/modelInference/sampleResnetQuickStart/cpp)，提示`ATC run success, welcome to the next use.`则说明转换成功。
  ```bash
  # 下载模型
  curl https://obs-9be7.obs.cn-east-2.myhuaweicloud.com/003_Atc_Models/resnet50/resnet50.onnx -o resnet50.onnx 

  # 转onnx为om，目标设备为310b
  atc --model=resnet50.onnx --framework=5 --output=resnet50 --input_shape="actual_input_1:1,3,224,224"  --soc_version=Ascend310
  ```

9. 如果还需要进一步测试，我们可以将转换后的`resnet50.om`文件拷贝到310b上面设备上执行，测试一下是不是能用，并且精度在预期范围内。



