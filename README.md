<!--
# Copyright (c) 2018-2020, NVIDIA CORPORATION. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-->

[![License](https://img.shields.io/badge/License-BSD3-lightgrey.svg)](https://opensource.org/licenses/BSD-3-Clause)

# Triton Inference Server

**NOTE: You are currently on the r20.12 branch which tracks stabilization
  towards the next release. This branch is not usable during stabilization.**
  
### Installation and Usage

The following dependencies must be installed before running Triton.

```
apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        autoconf \
        automake \
        build-essential \
        git \
        libb64-dev \
        libre2-dev \
        libssl-dev \
        libtool \
        libboost-dev \
        libcurl4-openssl-dev \
        rapidjson-dev \
        patchelf \
        zlib1g-dev
```

Other Dependencies

* [cmake >= 3.0.0](docs/cmake.md)

* There is no need [TensorRT](docs/tensorrt.md) for `JetPack4.x` but `Ubuntu 18.04`.

### Build With Cmake

Pull installation documentation.

```
$ git clone https://github.com/Beam-wi/tritonserver.git
$ cd tritonserver
$ git checkout r20.12
```

build.py installed 

```
$ python3 ./build.py --build-dir /opt/tritonserver --install-dir /opt/tritonserver/install --enable-logging \
--enable-stats --enable-tracing --enable-metrics --enable-gpu-metrics --enable-gpu --filesystem=gcs --filesystem=s3 \
--endpoint=http --endpoint=grpc --backend=custom --backend=ensemble --backend=tensorrt
```

* `r20.12` use container with `--container-version=version`, but higher without container `--no-container-build`.
* `Arm64` architecture non-supported `gcs` and `s3`, without `--filesystem=gcs` `--filesystem=s3`.
* Other backend with `--backend=backend_name`, which share lib add to environment variables.

Or terminal installed

```
$ mkdir ./builddir
$ cd builddir

$ cmake -DTRITON_ENABLE_TENSORRT=ON -DTRITON_ENABLE_GPU=ON -DTRITON_ENABLE_METRICS_GPU=ON -DTRITON_ENABLE_TRACING=ON \
-DTRITON_ENABLE_ENSEMBLE=ON -DTRITON_ENABLE_GCS=ON -DTRITON_ENABLE_S3=ON \
-DTRITON_EXTRA_LIB_PATHS="/usr/local/bin;/usr/local/include;/usr/local/lib;/usr/local/cuda;/usr/local/lib/python3.6/dist-packages" \
-DTRITON_ENABLE_GRPC=ON -DTRITON_ENABLE_HTTP=ON ../build

$ make -j24 server
$ make install

Add the share lib to -DTRITON_EXTRA_LIB_PATHS, only tensorrt was referenced in the demo.
```

Add to environment variables for Arm64

```
$ vim ~/.bashrc
adit:
    # tritonserver
    export LD_PRELOAD=/usr/local/cuda/targets/aarch64-linux/lib/stubs/libnvidia-ml.so
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/tritonserver/tritonserver/install/lib
$ source ~/.bashrc
```

To run the clients the following dependencies must be installed.

    apt-get install -y --no-install-recommends \
            curl \
            libopencv-dev=3.2.0+dfsg-4ubuntu0.1 \
            libopencv-core-dev=3.2.0+dfsg-4ubuntu0.1 \
            pkg-config \
            python3 \
            python3-pip \
            python3-dev

    python3 -m pip install --upgrade wheel setuptools
    python3 -m pip install --upgrade grpcio-tools numpy pillow
    
The Python wheel for the python client library is present in the tar file and can be installed by running the following command:

    python3 -m pip install --upgrade clients/python/tritonclient-2.6.0-py3-none-linux_aarch64.whl[all]

On jetson, the backend directory needs to be explicitly set with the `--backend-directory` flag. Triton also defaults to using `TensorFlow 1.x` 
and a version string is required to specify `TensorFlow 2.x`.

      tritonserver --model-repository=/path/to/model_repo --backend-directory=/path/to/tritonserver/backends \
             --backend-config=tensorflow,version=2		
		
### Model Repository
    
    $ cd Path~/tritonserver/qa/common
    $ python3 ./gen_qa_models.py --models_dir /Path~/model_repository/tensorrt --tensorrt
    
 Other model repository substitute `--tensorrt`
 
### Run Triton
    $ cd /opt/tritonserver/tritonserver/install/bin
    $ ./tritonserver --model-repository=/Path~/model_repository/tensorrt

