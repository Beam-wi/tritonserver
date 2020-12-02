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

# Contribution Rules

- The code style convention is enforced by clang-format. See below on
  how to ensure your contributions conform. In general please follow
  the existing conventions in the relevant file, submodule, module,
  and project when you add new code or when you extend/fix existing
  functionality.

- Avoid introducing unnecessary complexity into existing code so that
  maintainability and readability are preserved.

- Try to keep pull requests (PRs) as concise as possible:

  - Avoid committing commented-out code.

  - Wherever possible, each PR should address a single concern. If
    there are several otherwise-unrelated things that should be fixed
    to reach a desired endpoint, it is perfectly fine to open several
    PRs and state in the description which PR depends on another
    PR. The more complex the changes are in a single PR, the more time
    it will take to review those changes.

  - Make sure that the build log is clean, meaning no warnings or
    errors should be present.

- Make sure all `L0_*` tests pass:

  - In the `qa/` directory, there are basic sanity tests scripted in
    directories named `L0_...`.  See the Testing section in the
    Developer Guide for instructions on running these tests.

- Triton Inference Server's default build assumes recent versions of
  dependencies (CUDA, TensorFlow, PyTorch, TensorRT,
  etc.). Contributions that add compatibility with older versions of
  those dependencies will be considered, but NVIDIA cannot guarantee
  that all possible build configurations work, are not broken by
  future contributions, and retain highest performance.

- Make sure that you can contribute your work to open source (no
  license and/or patent conflict is introduced by your code). You need
  to complete the CLA described below before your PR can be merged.

- Thanks in advance for your patience as we review your contributions;
  we do appreciate them!

# Coding Convention

Use clang-format to format all source files (\*.h, \*.cc, \*.proto) to
a consistent format. You should run clang-format on all source files
before submitting a pull request::

  $ apt-get install clang-format clang-format-6.0

For convenience there is a format.py script in tools/ that can be used
to clang-format all files within the repo::

  $ cd .../triton-inference-server    # top-level of repo
  $ python3 format.py *

# Contributor License Agreement (CLA)

Triton requires that all contributors (or their corporate entity) send
a signed copy of the [Contributor License
Agreement](https://github.com/NVIDIA/triton-inference-server/blob/master/Triton-CCLA-v1.pdf)
to triton-cla@nvidia.com.