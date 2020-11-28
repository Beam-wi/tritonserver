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

### Jetson Jetpack Support

A release of Triton for the Developer Preview of JetPack 4.4 (https://developer.nvidia.com/embedded/jetpack) is provided in the attached 
file: `v2.5.0-jetpack4.4-1795341`.tgz. This release supports the `TensorFlow 2.3.1`, `TensorFlow 1.15.4`, `TensorRT 7.1`, and Custom backends as 
well as ensembles. `GPU` metrics, `GCS` storage and `S3` storage are not supported.

The tar file contains the Triton server executable and shared libraries and also the C++ and Python client libraries and examples.

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
$ git clone  https://github.com/Beam-wi/tritonserver.git
$ cd tritonserver
$ git checkout r20.11
```

build.py installed 

```
$ python3 ./build.py --build-dir /opt/tritonserver --install-dir /opt/tritonserver/install --enable-logging \
--enable-stats --enable-tracing --enable-metrics --enable-gpu-metrics --enable-gpu --filesystem=gcs --filesystem=s3 \
--endpoint=http --endpoint=grpc --backend=custom --backend=ensemble --backend=tensorrt
```

* `r20.11` use container with `--container-version=version`, without container must `--no-container-build`.
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
```
    Add the share lib to -DTRITON_EXTRA_LIB_PATHS, only tensorrt was referenced in the demo.

Add to environment variables for `Arm64`

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

    python3 -m pip install --upgrade clients/python/tritonclient-2.5.0-py3-none-linux_aarch64.whl[all]

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


# Building Triton

Triton is built using the [build.py](../build.py) script. The build.py
script supports both a Docker build and a non-Docker build.

* [Build using Docker](#building-triton-with-docker) and the
  TensorFlow and PyTorch containers from [NVIDIA GPU Cloud
  (NGC)](https://ngc.nvidia.com>).

* [Build without Docker](#building-triton-without-docker).

## Building Triton with Docker

The easiest way to build Triton is to use Docker. The result of the
build will be a Docker image called *tritonserver* that will contain
the tritonserver executable in /opt/tritonserver/bin and the required
shared libraries in /opt/tritonserver/lib. The backends built for
Triton will be in /opt/tritonserver/backends (note that as of the
20.11 release the TensorRT backend is still included in the core of
Triton and so does not appear in /opt/tritonserver/backends).

Building with Docker ensures that all the correct CUDA, cudnn,
TensorRT and other dependencies are handled for you. A Docker build is
the default when using build.py.

By default no Triton features are enabled. The following build.py
invocation builds all features and backends.

```
$ ./build.py --build-dir=/tmp/citritonbuild --enable-logging --enable-stats --enable-tracing --enable-metrics --enable-gpu-metrics --enable-gpu --filesystem=gcs --filesystem=s3 --endpoint=http --endpoint=grpc --repo-tag=common:<container tag> --repo-tag=core:<container tag> --repo-tag=backend:<container tag> --backend=custom --backend=ensemble --backend=tensorrt --backend=identity:<container tag> --backend=repeat:<container tag> --backend=square:<container tag> --backend=onnxruntime:<container tag> --backend=pytorch:<container tag> --backend=tensorflow1:<container tag> --backend=tensorflow2:<container tag> --backend=python:<container tag> --backend=dali:<container tag>
```

If you are building on master/main branch then <container tag> should
be set to "main". If you are building on a release branch you should
set the <container tag> to match. For example, if you are building on
the r20.11 branch you should set <container tag> to be "r20.11". You
can use a different <container tag> for a component to instead use the
corresponding branch/tag in the build. For example, if you have a
branch called "mybranch" in the
[identity_backend](https://github.com/triton-inference-server/identity_backend)
repo that you want to use in the build, you would specify
--backend=identity:mybranch.

By default build.py clones Triton repos from
https://github.com/triton-inference-server. Use the
--github-organization options to select a different URL.

The backends can also be built independently in each of the backend
repositories. See the [backend
repo](https://github.com/triton-inference-server/backend) for more
information.

## Building Triton without Docker

To build Triton without using Docker follow the [build.py steps
described above](#building-triton-with-docker) except that you must
also specify --no-container-build flag to build.py.

When building without Docker you must install the necessary CUDA
libraries and other dependencies needed for the build before invoking
build.py.

### CUDA, cuBLAS, cuDNN

For Triton to support NVIDIA GPUs you must install CUDA, cuBLAS and
cuDNN. These libraries must be installed on system include and library
paths so that they are available for the build. The version of the
libraries used in the Dockerfile build can be found in the [Framework
Containers Support
Matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html).

For a given version of Triton you can attempt to build with
non-supported versions of the libraries but you may have build or
execution issues since non-supported versions are not tested.

### TensorRT

The TensorRT includes and libraries must be installed on system
include and library paths so that they are available for the
build. The version of TensorRT used in the Dockerfile build can be
found in the [Framework Containers Support
Matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html).

For a given version of Triton you can attempt to build with
non-supported versions of TensorRT but you may have build or execution
issues since non-supported versions are not tested.

### TensorFlow

For instructions on how to build support for TensorFlow see the
[TensorFlow
backend](https://github.com/triton-inference-server/tensorflow_backend).

### ONNX Runtime

For instructions on how to build support for ONNX Runtime see the
[ONNX Runtime
backend](https://github.com/triton-inference-server/onnxruntime_backend)
and the CMakeLists.txt file contained in that repo. You must have a
version of the ONNX Runtime available on the build system and set the
TRITON_ONNXRUNTIME_INCLUDE_PATHS and TRITON_ONNXRUNTIME_LIB_PATHS
cmake variables appropriately.
