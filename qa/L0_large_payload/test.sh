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

REPO_VERSION=${NVIDIA_TRITON_SERVER_VERSION}
if [ "$#" -ge 1 ]; then
    REPO_VERSION=$1
fi
if [ -z "$REPO_VERSION" ]; then
    echo -e "Repository version must be specified"
    echo -e "\n***\n*** Test Failed\n***"
    exit 1
fi

export CUDA_VISIBLE_DEVICES=0

LARGE_PAYLOAD_TEST_PY=large_payload_test.py
CLIENT_LOG_BASE="./client.log"
DATADIR=`pwd`/models

SERVER=/opt/tritonserver/bin/tritonserver
SERVER_ARGS="--model-repository=$DATADIR --log-verbose=1"
SERVER_LOG_BASE="./inference_server.log"
source ../common/util.sh

rm -f $SERVER_LOG_BASE* $CLIENT_LOG_BASE*

RET=0

MODEL_SUFFIX=nobatch_zero_1_float32
rm -fr models && mkdir models
for TARGET in graphdef savedmodel onnx libtorch plan; do
    cp -r /data/inferenceserver/${REPO_VERSION}/qa_identity_model_repository/${TARGET}_$MODEL_SUFFIX \
       models/.
done
cp -r ../custom_models/custom_zero_1_float32 models/. && \
    mkdir -p models/custom_zero_1_float32/1 && \
    cp `pwd`/libidentity.so models/custom_zero_1_float32/1/. && \
    (cd models/custom_zero_1_float32 && \
            echo "default_model_filename: \"libidentity.so\"" >> config.pbtxt && \
            echo "instance_group [ { kind: KIND_CPU }]" >> config.pbtxt && \
            sed -i "s/max_batch_size: 1/max_batch_size: 0/" config.pbtxt && \
            sed -i "s/dims: \[ 1 \]/dims: \[ -1 \]/" config.pbtxt)

mkdir -p models/python_$MODEL_SUFFIX/1/
cp ../python_models/identity_fp32/config.pbtxt models/python_$MODEL_SUFFIX/
(cd models/python_$MODEL_SUFFIX && \
            sed -i "s/max_batch_size: 64/max_batch_size: 0/" config.pbtxt && \
            sed -i "s/name: \"identity_fp32\"/name: \"python_$MODEL_SUFFIX\"/" config.pbtxt)

cp ../python_models/identity_fp32/model.py models/python_$MODEL_SUFFIX/1/model.py

# Restart server before every test to make sure server state
# is invariant to previous test
for TARGET in graphdef savedmodel onnx libtorch custom plan python; do
    SERVER_LOG=$SERVER_LOG_BASE.$TARGET
    CLIENT_LOG=$CLIENT_LOG_BASE.$TARGET

    run_server
    if [ "$SERVER_PID" == "0" ]; then
        echo -e "\n***\n*** Failed to start $SERVER\n***"
        cat $SERVER_LOG
        exit 1
    fi

    set +e

    python $LARGE_PAYLOAD_TEST_PY LargePayLoadTest.test_$TARGET >$CLIENT_LOG 2>&1
    if [ $? -ne 0 ]; then
        cat $CLIENT_LOG
        echo -e "\n***\n*** Test Failed\n***"
        RET=1
    else
        check_test_results $CLIENT_LOG 1
        if [ $? -ne 0 ]; then
            cat $CLIENT_LOG
            echo -e "\n***\n*** Test Result Verification Failed\n***"
            RET=1
        fi
    fi

    set -e

    kill $SERVER_PID
    wait $SERVER_PID
done

if [ $RET -eq 0 ]; then
  echo -e "\n***\n*** Test Passed\n***"
fi

exit $RET
