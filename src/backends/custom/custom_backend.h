// Copyright (c) 2018-2020, NVIDIA CORPORATION. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of NVIDIA CORPORATION nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#pragma once

#include "src/backends/custom/custom.h"
#include "src/core/backend.h"
#include "src/core/backend_context.h"
#include "src/core/infer_request.h"
#include "src/core/metric_model_reporter.h"
#include "src/core/model_config.pb.h"
#include "src/core/scheduler.h"
#include "src/core/status.h"

namespace nvidia { namespace inferenceserver {

class CustomBackend : public InferenceBackend {
 public:
  explicit CustomBackend(const double min_compute_capability)
      : InferenceBackend(min_compute_capability)
  {
  }
  CustomBackend(CustomBackend&&) = default;

  Status Init(
      const std::string& path, const std::vector<std::string>& server_params,
      const inference::ModelConfig& config);

  // Create a context for execution for each instance for the custom
  // 'models'.
  Status CreateExecutionContexts(
      const std::unordered_map<std::string, std::string>& libraries);
  Status CreateExecutionContext(
      const std::string& instance_name, const int gpu_device,
      const std::unordered_map<std::string, std::string>& libraries);

 private:
  // Init model on the context associated with 'runner_idx'.
  Status InitBackend(uint32_t runner_idx);

 private:
  DISALLOW_COPY_AND_ASSIGN(CustomBackend);
  friend std::ostream& operator<<(std::ostream&, const CustomBackend&);
  friend bool CustomGetNextInput(void*, const char*, const void**, uint64_t*);
  friend bool CustomGetOutput(
      void*, const char*, size_t, int64_t*, uint64_t, void**);
  friend bool CustomGetNextInputV2(
      void*, const char*, const void**, uint64_t*, CustomMemoryType*, int64_t*);
  friend bool CustomGetOutputV2(
      void*, const char*, size_t, int64_t*, uint64_t, void**, CustomMemoryType*,
      int64_t*);

  // For each model instance there is a context.
  struct Context : BackendContext {
    using IOSizeMap = std::unordered_map<std::string, size_t>;

    Context(
        const std::string& name, const int gpu_device, const int max_batch_size,
        const bool enable_pinned_input, const bool enable_pinned_output,
        std::unique_ptr<MetricModelReporter>&& metric_reporter);
    ~Context();

    DISALLOW_MOVE(Context);
    DISALLOW_COPY_AND_ASSIGN(Context);

    // Return the shared library reported error string for 'err'.
    std::string LibraryErrorString(const int err);

    // See BackendContext::Run()
    void Run(
        InferenceBackend* base,
        std::vector<std::unique_ptr<InferenceRequest>>&& requests) override;

    struct GetInputOutputContext {
      GetInputOutputContext(
          CustomBackend::Context* context, InferenceRequest* request)
          : context_(context), request_(request)
      {
      }
      CustomBackend::Context* context_;
      InferenceRequest* request_;
      std::unique_ptr<InferenceResponse> response_;

      // Map from input to the buffer index for the tensor data for
      // that input.
      std::unordered_map<const InferenceRequest::Input*, size_t>
          input_data_idx_;

      // Variable for being compatible with V1 interface in the case
      // of GPU I/O
      std::vector<std::unique_ptr<char[]>> input_buffers_;
      std::vector<std::tuple<void*, std::unique_ptr<char[]>, uint64_t>>
          output_buffers_;
    };

    // Callback used by custom backends to get the next block of input
    // for a 'name'd input tensor. This function will enforce that
    // the 'content' will be in CPU memory.
    bool GetNextInput(
        GetInputOutputContext* input_context, const char* name,
        const void** content, uint64_t* content_byte_size);

    // Callback used by custom backends to get the next block of input
    // for a 'name'd input tensor.
    bool GetNextInput(
        GetInputOutputContext* input_context, const char* name,
        const void** content, uint64_t* content_byte_size,
        CustomMemoryType* memory_type, int64_t* memory_type_id);

    // Callback used by custom backends to get the output buffer for a
    // 'name'd output tensor. This function will enforce that
    // the 'content' will be in CPU memory.
    bool GetOutput(
        GetInputOutputContext* output_context, const char* name,
        size_t shape_dim_cnt, int64_t* shape_dims, uint64_t content_byte_size,
        void** content);

    // Callback used by custom backends to get the output buffer for a
    // 'name'd output tensor.
    bool GetOutput(
        GetInputOutputContext* output_context, const char* name,
        size_t shape_dim_cnt, int64_t* shape_dims, uint64_t content_byte_size,
        void** content, CustomMemoryType* memory_type, int64_t* memory_type_id);

    // The handle to the shared library associated with this context.
    void* library_handle_;

    // The handle to the custom shared library context associated with
    // this context.
    void* library_context_handle_;

    // The functions from the shared library.
    CustomInitializeFn_t InitializeFn_;
    CustomFinalizeFn_t FinalizeFn_;
    CustomErrorStringFn_t ErrorStringFn_;
    CustomExecuteFn_t ExecuteFn_;
    CustomExecuteV2Fn_t ExecuteV2Fn_;

    // The version of the custom interface.
    int custom_version_;

    // The shape for input tensors that have fixed size. These are
    // collected at init time as a performance optimization. Input
    // tensors with variable size must have their shape determine for
    // each inference request and so are not included here.
    std::unordered_map<std::string, std::unique_ptr<std::vector<int64_t>>>
        fixed_input_shapes_;

    // Map from each output to the datatype for the output. The custom
    // V1/V2 API doesn't require the backend to indicate an output
    // datatype so we need to use the datatype from the model
    // configuration.
    std::unordered_map<std::string, inference::DataType> output_datatypes_;

    // The current device from last model execution. Use to ensure invariant
    // from custom backend's point of view.
    int current_execute_device_;
  };

  std::vector<std::string> server_params_;
};

std::ostream& operator<<(std::ostream& out, const CustomBackend& pb);

// Callback used by custom backends to get the next block of input for
// a 'name'd input tensor. The block will be guaranteed to be in CPU memory.
bool CustomGetNextInput(
    void* input_context, const char* name, const void** content,
    uint64_t* content_byte_size);

// Callback used by custom backends to get the output buffer for a
// 'name'd output tensor. The buffer will be in CPU memory.
bool CustomGetOutput(
    void* output_context, const char* name, size_t shape_dim_cnt,
    int64_t* shape_dims, uint64_t content_byte_size, void** content);

// See CustomGetNextInput, except that the block may not be in CPU memory.
// Thus 'memory_type' acts as both input and output. On input gives the buffer
// memory type preferred by the function caller. On output returns
// the actual memory type of 'content'. 'memory_type_id' also acts as
// both input and output. On input gives the buffer memory type id preferred by
// the function caller. On output returns the actual memory type of 'content'.
bool CustomGetNextInputV2(
    void* input_context, const char* name, const void** content,
    uint64_t* content_byte_size, CustomMemoryType* memory_type,
    int64_t* memory_type_id);

// See CustomGetOutput, except that the buffer is not limited to be
// in CPU memory. 'memory_type' acts as both input and output. On input
// gives the buffer memory type preferred by the function caller. On output
// returns the actual memory type of 'content'. 'memory_type_id' also acts as
// both input and output. On input gives the buffer memory type id preferred by
// the function caller. On output returns the actual memory type of 'content'.
bool CustomGetOutputV2(
    void* output_context, const char* name, size_t shape_dim_cnt,
    int64_t* shape_dims, uint64_t content_byte_size, void** content,
    CustomMemoryType* memory_type, int64_t* memory_type_id);

}}  // namespace nvidia::inferenceserver
