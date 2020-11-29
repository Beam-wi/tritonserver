// Copyright (c) 2018-2019, NVIDIA CORPORATION. All rights reserved.
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

#include "src/backends/caffe2/autofill.h"

#include "src/core/autofill.h"
#include "src/core/constants.h"
#include "src/core/filesystem.h"

namespace nvidia { namespace inferenceserver {

class AutoFillNetDefImpl : public AutoFill {
 public:
  AutoFillNetDefImpl(const std::string& model_name) : AutoFill(model_name) {}
  Status Fix(inference::ModelConfig* config) override;
};

Status
AutoFillNetDefImpl::Fix(inference::ModelConfig* config)
{
  config->set_platform(kCaffe2NetDefPlatform);

  // Set name if not already set.
  if (config->name().empty()) {
    config->set_name(model_name_);
  }

  return Status::Success;
}

Status
AutoFillNetDef::Create(
    const std::string& model_name, const std::string& model_path,
    std::unique_ptr<AutoFill>* autofill)
{
  std::set<std::string> version_dirs;
  RETURN_IF_ERROR(GetDirectorySubdirs(model_path, &version_dirs));

  // There must be at least one version directory that we can inspect to
  // attempt to determine the platform. For now we allow multiple versions
  // and only inspect the first verison directory to ensure it is valid.
  // We can add more aggressive checks later.
  if (version_dirs.size() == 0) {
    return Status(
        Status::Code::INTERNAL, "unable to autofill for '" + model_name +
                                    "' due to no version directories");
  }

  const auto version_path = JoinPath({model_path, *(version_dirs.begin())});

  std::set<std::string> netdef_files;
  RETURN_IF_ERROR(GetDirectoryFiles(
      version_path, true /* skip_hidden_files */, &netdef_files));
  const std::string expected_init_filename =
      std::string(kCaffe2NetDefInitFilenamePrefix) +
      std::string(kCaffe2NetDefFilename);

  // If find both files named with the default netdef names then
  // assume it is a netdef. In the future we can be smarter here and
  // try to parse to see if it really is a netdef, and then try to
  // derive more of the configuration...
  if ((netdef_files.find(expected_init_filename) == netdef_files.end()) ||
      (netdef_files.find(kCaffe2NetDefFilename) == netdef_files.end())) {
    return Status(
        Status::Code::INTERNAL, "unable to autofill for '" + model_name +
                                    "', unable to find netdef files: '" +
                                    kCaffe2NetDefFilename + "' and '" +
                                    expected_init_filename + "'");
  }

  autofill->reset(new AutoFillNetDefImpl(model_name));
  return Status::Success;
}

}}  // namespace nvidia::inferenceserver
