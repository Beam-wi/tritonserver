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

Triton Inference Server provides a cloud and edge inferencing solution
optimized for both CPUs and GPUs. Triton supports an HTTP/REST and
GRPC protocol that allows remote clients to request inferencing for
any model being managed by the server. For edge deployments, Triton is
available as a shared library with a C API that allows the full
functionality of Triton to be included directly in an
application.

## What's New in 2.5.0

* ONNX Runtime backend updated to use ONNX Runtime 1.5.3.

* The PyTorch backend is moved to a dedicated repo 
  triton-inference-server/pytorch_backend.

* The Caffe2 backend is removed. Caffe2 models are no longer supported.

* Fix handling of failed model reloads. If a model reload fails, the currently 
  loaded version of the model will remain loaded and its availability will be uninterrupted. 

* Releasing Triton ModelAnalyzer in the Triton SDK container and as a PIP 
  package available in NVIDIA PyIndex.

## Features

* [Multiple deep-learning
  frameworks](https://github.com/triton-inference-server/backend). Triton
  can manage any number and mix of models (limited by system disk and
  memory resources). Triton supports TensorRT, TensorFlow GraphDef,
  TensorFlow SavedModel, ONNX, and PyTorch TorchScript model
  formats. Both TensorFlow 1.x and TensorFlow 2.x are
  supported. Triton also supports TensorFlow-TensorRT and
  ONNX-TensorRT integrated models.

* [Concurrent model
  execution](docs/architecture.md#concurrent-model-execution). Multiple
  models (or multiple instances of the same model) can run
  simultaneously on the same GPU or on multiple GPUs.

* [Dynamic batching](docs/architecture.md#models-and-schedulers). For
  models that support batching, Triton implements multiple scheduling
  and batching algorithms that combine individual inference requests
  together to improve inference throughput. These scheduling and
  batching decisions are transparent to the client requesting
  inference.

* [Extensible
  backends](https://github.com/triton-inference-server/backend). In
  addition to deep-learning frameworks, Triton provides a *backend
  API* that allows Triton to be extended with any model execution
  logic implemented in
  [Python](https://github.com/triton-inference-server/python_backend)
  or
  [C++](https://github.com/triton-inference-server/backend/blob/main/README.md#triton-backend-api),
  while still benefiting from the CPU and GPU support, concurrent
  execution, dynamic batching and other features provided by Triton.

* [Model pipelines](docs/architecture.md#ensemble-models). Triton
  *ensembles* represents a pipeline of one or more models and the
  connection of input and output tensors between those models. A
  single inference request to an ensemble will trigger the execution
  of the entire pipeline.

* [HTTP/REST and GRPC inference
  protocols](docs/inference_protocols.md) based on the community
  developed [KFServing
  protocol](https://github.com/kubeflow/kfserving/tree/master/docs/predict-api/v2).

* [Metrics](docs/metrics.md) indicating GPU utilization, server
  throughput, and server latency. The metrics are provided in
  Prometheus data format.

## Documentation

[Triton Architecture](docs/architecture.md) gives a high-level
overview of the structure and capabilities of the inference
server. There is also an [FAQ](docs/faq.md). Additional documentation
is divided into [*user*](#user-documentation) and
[*developer*](#developer-documentation) sections. The *user*
documentation describes how to use Triton as an inference solution,
including information on how to configure Triton, how to organize and
configure your models, how to use the C++ and Python clients, etc. The
*developer* documentation describes how to build and test Triton and
also how Triton can be extended with new functionality.

The Triton [Release
Notes](https://docs.nvidia.com/deeplearning/triton-inference-server/release-notes/index.html)
and [Support
Matrix](https://docs.nvidia.com/deeplearning/dgx/support-matrix/index.html)
indicate the required versions of the NVIDIA Driver and CUDA, and also
describe supported GPUs.

### User Documentation

- [QuickStart](docs/quickstart.md)
  - [Install](docs/quickstart.md#install-triton-docker-image)
  - [Run](docs/quickstart.md#run-triton)
- [Model Repository](docs/model_repository.md)
- [Model Configuration](docs/model_configuration.md)
- [Model Management](docs/model_management.md)
- [Custom Operations](docs/custom_operations.md)
- [Client Libraries](docs/client_libraries.md)
- [Client Examples](docs/client_examples.md)
- [Optimization](docs/optimization.md)
  - [Model Analyzer](docs/model_analyzer.md)
  - [Performance Analyzer](docs/perf_analyzer.md)
- [Metrics](docs/metrics.md)

The [quickstart](docs/quickstart.md) walks you through all the steps
required to install and run Triton with an example image
classification model and then use an example client application to
perform inferencing using that model. The quickstart also demonstrates
how [Triton supports both GPU systems and CPU-only
systems](docs/quickstart.md#run-triton).

The first step in using Triton to serve your models is to place one or
more models into a [model
repository](docs/model_repository.md). Optionally, depending on the type
of the model and on what Triton capabilities you want to enable for
the model, you may need to create a [model
configuration](docs/model_configuration.md) for the model.  If your
model has [custom operations](docs/custom_operations.md) you will need
to make sure they are loaded correctly by Triton.

After you have your model(s) available in Triton, you will want to
send inference and other requests to Triton from your *client*
application. The [Python and C++ client
libraries](docs/client_libraries.md) provide
[APIs](docs/client_libraries.md#client-library-apis) to simplify this
communication. There are also a large number of [client
examples](docs/client_examples.md) that demonstrate how to use the
libraries.  You can also send HTTP/REST requests directly to Triton
using the [HTTP/REST JSON-based
protocol](docs/inference_protocols.md#httprest-and-grpc-protocols) or
[generate a GRPC client for many other
languages](docs/client_libraries.md).

Understanding and [optimizing performance](docs/optimization.md) is an
important part of deploying your models. The Triton project provides
the [Performance Analyzer](docs/perf_analyzer.md) and the [Model
Analyzer](docs/model_analyzer.md) to help your optimization
efforts. Specifically, you will want to optimize [scheduling and
batching](docs/architecture.md#models-and-schedulers) and [model
instances](docs/model_configuration.md#instance-groups) appropriately
for each model. You may also want to consider [ensembling multiple
models and pre/post-processing](docs/architecture.md#ensemble-models)
into a pipeline. In some cases you may find [individual inference
request trace data](docs/trace.md) useful when optimizing. A
[Prometheus metrics endpoint](docs/metrics.md) allows you to visualize
and monitor aggregate inference metrics.

NVIDIA publishes a number of [deep learning
examples](https://github.com/NVIDIA/DeepLearningExamples) that use
Triton.

As part of you deployment strategy you may want to [explicitly manage
what models are available by loading and unloading
models](docs/model_management.md) from a running Triton server. If you
are using Kubernetes for deployment a simple example of how to [deploy
Triton using Kubernetes and Helm](deploy/single_server/README.rst) may
be helpful.

The [version 1 to version 2 migration
information](docs/v1_to_v2.md) is helpful if you are moving to
version 2 of Triton from previously using version 1.

### Jetson Jetpack Support

A release of Triton for the Developer Preview of JetPack 4.4 (https://developer.nvidia.com/embedded/jetpack) is provided in the attached 
file: `v2.5.0-jetpack4.4-1795341.tgz`. This release supports the `TensorFlow 2.3.1`, `TensorFlow 1.15.3`, `TensorRT 7.1`, and Custom backends as 
well as ensembles. GPU metrics, GCS storage and S3 storage are not supported.

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

`build.py` installed 

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

    python3 -m pip install --upgrade clients/python/tritonclient-2.4.0-py3-none-linux_aarch64.whl[all]

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

### Developer Documentation

- [Build](docs/build.md)
- [Protocols and APIs](docs/inference_protocols.md).
- [Backends](https://github.com/triton-inference-server/backend)
- [Test](docs/test.md)

Triton can be [built using
Docker](docs/build.md#building-triton-with-docker) or [built without
Docker](docs/build.md#building-triton-without-docker). After building
you should [test Triton](docs/test.md).

Starting with the r20.10 release, it is also possible to [create a
Docker image containing a customized Triton](docs/compose.md) that
contains only a subset of the backends.

The Triton project also provides [client libraries for Python and
C++](docs/client_libraries.md) that make it easy to communicate with
the server. There are also a large number of [example
clients](docs/client_examples.md) that demonstrate how to use the
libraries. You can also develop your own clients that directly
communicate with Triton using [HTTP/REST or GRPC
protocols](docs/inference_protocols.md). There is also a [C
API](docs/inference_protocols.md) that allows Triton to be linked
directly into your application.

A [Triton backend](https://github.com/triton-inference-server/backend)
is the implementation that executes a model. A backend can interface
with a deep learning framework, like PyTorch, TensorFlow, TensorRT or
ONNX Runtime; or it can interface with a data processing framework
like [DALI](https://github.com/triton-inference-server/dali_backend);
or it can be custom
[C/C++](https://github.com/triton-inference-server/backend/blob/main/README.md#triton-backend-api)
or [Python](https://github.com/triton-inference-server/python_backend)
code for performing any operation. You can even extend Triton by
[writing your own
backend](https://github.com/triton-inference-server/backend).

## Papers and Presentation

* [Maximizing Deep Learning Inference Performance with NVIDIA Model
  Analyzer](https://developer.nvidia.com/blog/maximizing-deep-learning-inference-performance-with-nvidia-model-analyzer/).

* [High-Performance Inferencing at Scale Using the TensorRT Inference
  Server](https://developer.nvidia.com/gtc/2020/video/s22418).

* [Accelerate and Autoscale Deep Learning Inference on GPUs with
  KFServing](https://developer.nvidia.com/gtc/2020/video/s22459).

* [Deep into Triton Inference Server: BERT Practical Deployment on
  NVIDIA GPU](https://developer.nvidia.com/gtc/2020/video/s21736).

* [Maximizing Utilization for Data Center Inference with TensorRT
  Inference Server](https://on-demand-gtc.gputechconf.com/gtcnew/sessionview.php?sessionName=s9438-maximizing+utilization+for+data+center+inference+with+tensorrt+inference+server).

* [NVIDIA TensorRT Inference Server Boosts Deep Learning
  Inference](https://devblogs.nvidia.com/nvidia-serves-deep-learning-inference/).

* [GPU-Accelerated Inference for Kubernetes with the NVIDIA TensorRT
  Inference Server and
  Kubeflow](https://www.kubeflow.org/blog/nvidia_tensorrt/).

## Contributing

Contributions to Triton Inference Server are more than welcome. To
contribute make a pull request and follow the guidelines outlined in
[CONTRIBUTING.md](CONTRIBUTING.md). If you have a backend, client,
example or similar contribution that is not modifying the core of
Triton, then you should file a PR in the [contrib
repo](https://github.com/triton-inference-server/contrib).

## Reporting problems, asking questions

We appreciate any feedback, questions or bug reporting regarding this
project. When help with code is needed, follow the process outlined in
the Stack Overflow (https://stackoverflow.com/help/mcve)
document. Ensure posted examples are:

* minimal – use as little code as possible that still produces the
  same problem

* complete – provide all parts needed to reproduce the problem. Check
  if you can strip external dependency and still show the problem. The
  less time we spend on reproducing problems the more time we have to
  fix it

* verifiable – test the code you're about to provide to make sure it
  reproduces the problem. Remove all other problems that are not
  related to your request/question.