#!/bin/bash
# Copyright (c) 2019-2020, NVIDIA CORPORATION. All rights reserved.
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

REPO_VERSION=$1

BACKENDS=${BACKENDS:="plan custom graphdef savedmodel onnx libtorch"}
STATIC_BATCH_SIZES=${STATIC_BATCH_SIZES:=1}
DYNAMIC_BATCH_SIZES=${DYNAMIC_BATCH_SIZES:=1}
INSTANCE_COUNTS=${INSTANCE_COUNTS:=1}
CONCURRENCY=${CONCURRENCY:=1}

PERF_CLIENT=../clients/perf_client
PERF_CLIENT_PROTOCOL=${PERF_CLIENT_PROTOCOL:=grpc}
PERF_CLIENT_PERCENTILE=${PERF_CLIENT_PERCENTILE:=95}
PERF_CLIENT_STABILIZE_WINDOW=${PERF_CLIENT_STABILIZE_WINDOW:=5000}
PERF_CLIENT_STABILIZE_THRESHOLD=${PERF_CLIENT_STABILIZE_THRESHOLD:=5}
TENSOR_SIZE=${TENSOR_SIZE:=1}
SHARED_MEMORY=${SHARED_MEMORY:="none"}
REPORTER=../common/reporter.py

DATADIR=/data/inferenceserver/${REPO_VERSION}
RESULTDIR=${RESULTDIR:=.}

SERVER=/opt/tritonserver/bin/tritonserver
SERVER_ARGS="--model-repository=`pwd`/models"
source ../common/util.sh

# Select the single GPU that will be available to the inference server
export CUDA_VISIBLE_DEVICES=0

mkdir -p ${RESULTDIR}
RET=0

rm -fr ./custom_models && mkdir ./custom_models && \
    cp -r ../custom_models/custom_zero_1_float32 ./custom_models/. && \
    mkdir -p ./custom_models/custom_zero_1_float32/1 && \
    cp ./libidentity.so ./custom_models/custom_zero_1_float32/1/libcustom.so

PERF_CLIENT_PERCENTILE_ARGS="" &&
    (( ${PERF_CLIENT_PERCENTILE} != 0 )) &&
    PERF_CLIENT_PERCENTILE_ARGS="--percentile=${PERF_CLIENT_PERCENTILE}"
PERF_CLIENT_EXTRA_ARGS="$PERF_CLIENT_PERCENTILE_ARGS --shared-memory \"${SHARED_MEMORY}\""

#
# Use "identity" model for all model types.
#
for BACKEND in $BACKENDS; do
 for STATIC_BATCH in $STATIC_BATCH_SIZES; do
  for DYNAMIC_BATCH in $DYNAMIC_BATCH_SIZES; do
   for INSTANCE_CNT in $INSTANCE_COUNTS; do
    if (( ($DYNAMIC_BATCH > 1) && ($STATIC_BATCH >= $DYNAMIC_BATCH) )); then
        continue
    fi

    # plan model support max batch size of 32 only. Skip for 16MB I/O tests
    if [ $BACKEND == "plan" ]; then
        continue
    fi

    # set naming (special case for libtorch model)
    INPUT_NAME="INPUT0" && [ $BACKEND == "libtorch" ] && INPUT_NAME="INPUT__0"

    MAX_LATENCY=300
    MAX_BATCH=${STATIC_BATCH} && [ $DYNAMIC_BATCH > $STATIC_BATCH ] && MAX_BATCH=${DYNAMIC_BATCH}

    if [ $DYNAMIC_BATCH > 1 ]; then
        NAME=${BACKEND}_sbatch${STATIC_BATCH}_dbatch${DYNAMIC_BATCH}_instance${INSTANCE_CNT}
    else
        NAME=${BACKEND}_sbatch${STATIC_BATCH}_instance${INSTANCE_CNT}
    fi

    MODEL_NAME=${BACKEND}_zero_1_float32
    REPO_DIR=./custom_models && \
        [ $BACKEND != "custom" ] && REPO_DIR=$DATADIR/qa_identity_model_repository
    SHAPE=${TENSOR_SIZE}
    KIND="KIND_GPU" && [ $BACKEND == "custom" ] && KIND="KIND_CPU"

    rm -fr models && mkdir -p models && \
        cp -r $REPO_DIR/$MODEL_NAME models/. && \
        (cd models/$MODEL_NAME && \
                sed -i "s/^max_batch_size:.*/max_batch_size: ${MAX_BATCH}/" config.pbtxt && \
                echo "instance_group [ { kind: ${KIND}, count: ${INSTANCE_CNT} }]" >> config.pbtxt)
    if [ $BACKEND == "custom" ]; then
        (cd models/$MODEL_NAME && \
            sed -i "s/dims:.*\[.*\]/dims: \[ ${SHAPE} \]/g" config.pbtxt)
    fi
    if [ $DYNAMIC_BATCH > 1 ]; then
        (cd models/$MODEL_NAME && \
                echo "dynamic_batching { preferred_batch_size: [ ${DYNAMIC_BATCH} ] }" >> config.pbtxt)
    fi

    SERVER_LOG="${RESULTDIR}/${NAME}.serverlog"
    run_server
    if [ $SERVER_PID == 0 ]; then
        echo -e "\n***\n*** Failed to start $SERVER\n***"
        cat $SERVER_LOG
        exit 1
    fi

    set +e
    $PERF_CLIENT -v \
                 -p${PERF_CLIENT_STABILIZE_WINDOW} \
                 -s${PERF_CLIENT_STABILIZE_THRESHOLD} \
                 ${PERF_CLIENT_EXTRA_ARGS} \
                 -i ${PERF_CLIENT_PROTOCOL} -m ${MODEL_NAME} \
                 -b${STATIC_BATCH} -t${CONCURRENCY} \
                 --shape ${INPUT_NAME}:${SHAPE} \
                 -f ${RESULTDIR}/${NAME}.csv >> ${RESULTDIR}/${NAME}.log 2>&1
    if [ $? -ne 0 ]; then
        RET=1
    fi
    curl localhost:8002/metrics -o ${RESULTDIR}/${NAME}.metrics >> ${RESULTDIR}/${NAME}.log 2>&1
    if [ $? -ne 0 ]; then
        RET=1
    fi
    set -e

    echo -e "[{\"s_benchmark_kind\":\"benchmark_perf\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"s_benchmark_name\":\"nomodel\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"s_protocol\":\"${PERF_CLIENT_PROTOCOL}\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"s_framework\":\"${BACKEND}\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"s_model\":\"${MODEL_NAME}\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"l_concurrency\":${CONCURRENCY}," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"l_dynamic_batch_size\":${DYNAMIC_BATCH}," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"l_batch_size\":${STATIC_BATCH}," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"l_size\":${TENSOR_SIZE}," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"s_shared_memory\":\"${SHARED_MEMORY}\"," >> ${RESULTDIR}/${NAME}.tjson
    echo -e "\"l_instance_count\":${INSTANCE_CNT}}]" >> ${RESULTDIR}/${NAME}.tjson

    kill $SERVER_PID
    wait $SERVER_PID

    if [ -f $REPORTER ]; then
        set +e

        URL_FLAG=
        if [ ! -z ${BENCHMARK_REPORTER_URL} ]; then
            URL_FLAG="-u ${BENCHMARK_REPORTER_URL}"
        fi

        $REPORTER -v -o ${RESULTDIR}/${NAME}.json --csv ${RESULTDIR}/${NAME}.csv ${URL_FLAG} ${RESULTDIR}/${NAME}.tjson
        if [ $? -ne 0 ]; then
            RET=1
        fi

        set -e
    fi
   done
  done
 done
done

if [ $RET == 0 ]; then
    echo -e "\n***\n*** Test ${RESULTNAME} Passed\n***"
else
    echo -e "\n***\n*** Test ${RESULTNAME} FAILED\n***"
fi

exit $RET
