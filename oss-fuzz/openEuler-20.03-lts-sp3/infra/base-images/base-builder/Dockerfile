# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FROM gcr.io/oss-fuzz-base/base-clang:openeuler-20.03-lts-sp3

RUN yum clean all && \
    yum makecache && \
    yum install -y \
        binutils-devel \
        gcc-c++ \
        kernel-devel \
        curl \
        wget \
        git \
        jq \
        glibc-devel \
        # glibc-devel.i686 \
        rsync \
        subversion \
        zip \
        https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/p/patchelf-0.12-1.el7.x86_64.rpm --nogpgcheck 

# Build and install latest Python 3 (3.8.3).
ENV PYTHON_VERSION 3.8.3
RUN export PYTHON_DEPS="\
        zlib-devel \
        ncurses-devel \
        ncurses-libs \
        gdbm-devel \
        nss-devel \
        openssl-devel \
        sqlite-devel \
        readline \
        readline-devel \
        libffi \
        libffi-devel \
        bzip2-devel \
        lzma-devel" && \
    unset CFLAGS CXXFLAGS && \
    yum install -y $PYTHON_DEPS --nogpgcheck  && \
    cd /tmp && \
    curl -O https://mirrors.huaweicloud.com/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz && \   
    tar -xvf Python-$PYTHON_VERSION.tar.xz && \
    cd Python-$PYTHON_VERSION && \
    ./configure --enable-optimizations --enable-shared && \
    make -j install && \
    ldconfig && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    cd .. && \
    rm -r /tmp/Python-$PYTHON_VERSION.tar.xz /tmp/Python-$PYTHON_VERSION && \
    rm -rf /usr/local/lib/python3.8/test && \
    # yum remove -y $PYTHON_DEPS # https://github.com/google/oss-fuzz/issues/3888
    cp /usr/local/lib/libpython3.8.so.1.0 /usr/lib64/

# Install six for Bazel rules.
RUN unset CFLAGS CXXFLAGS && pip3 install -v --no-cache-dir six==1.15.0  -i http://pypi.douban.com/simple --trusted-host pypi.douban.com && \
    rm -rf /tmp/*

# Install Bazel through Bazelisk, which automatically fetches the latest Bazel version.
ENV BAZELISK_VERSION 1.9.0

RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v$BAZELISK_VERSION/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Default build flags for various sanitizers.
ENV SANITIZER_FLAGS_address "-fsanitize=address -fsanitize-address-use-after-scope"

# Set of '-fsanitize' flags matches '-fno-sanitize-recover' + 'unsigned-integer-overflow'.
ENV SANITIZER_FLAGS_undefined "-fsanitize=array-bounds,bool,builtin,enum,float-divide-by-zero,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unsigned-integer-overflow,unreachable,vla-bound,vptr -fno-sanitize-recover=array-bounds,bool,builtin,enum,float-divide-by-zero,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"

ENV SANITIZER_FLAGS_memory "-fsanitize=memory -fsanitize-memory-track-origins"

ENV SANITIZER_FLAGS_dataflow "-fsanitize=dataflow"

ENV SANITIZER_FLAGS_thread "-fsanitize=thread"

ENV SANITIZER_FLAGS_introspector "-flegacy-pass-manager -flto -fno-inline-functions"

# Do not use any sanitizers in the coverage build.
ENV SANITIZER_FLAGS_coverage ""

# We use unsigned-integer-overflow as an additional coverage signal and have to
# suppress error messages. See https://github.com/google/oss-fuzz/issues/910.
ENV UBSAN_OPTIONS="silence_unsigned_overflow=1"

# To suppress warnings from binaries running during compilation.
ENV DFSAN_OPTIONS='warn_unimplemented=0'

# Default build flags for coverage feedback.
ENV COVERAGE_FLAGS="-fsanitize=fuzzer-no-link"

# Use '-Wno-unused-command-line-argument' to suppress "warning: -ldl: 'linker' input unused"
# messages which are treated as errors by some projects.
ENV COVERAGE_FLAGS_coverage "-fprofile-instr-generate -fcoverage-mapping -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument"

# Coverage isntrumentation flags for dataflow builds.
ENV COVERAGE_FLAGS_dataflow="-fsanitize-coverage=trace-pc-guard,pc-table,bb,trace-cmp"

# Default sanitizer, fuzzing engine and architecture to use.
ENV SANITIZER="address"
ENV FUZZING_ENGINE="libfuzzer"
ENV ARCHITECTURE="x86_64"

# DEPRECATED - NEW CODE SHOULD NOT USE THIS. OLD CODE SHOULD STOP. Please use
# LIB_FUZZING_ENGINE instead.
# Path to fuzzing engine library to support some old users of
# LIB_FUZZING_ENGINE.
ENV LIB_FUZZING_ENGINE_DEPRECATED="/usr/lib/libFuzzingEngine.a"

# Argument passed to compiler to link against fuzzing engine.
# Defaults to the path, but is "-fsanitize=fuzzer" in libFuzzer builds.
ENV LIB_FUZZING_ENGINE="/usr/lib/libFuzzingEngine.a"

# TODO: remove after tpm2 catchup.
ENV FUZZER_LDFLAGS ""

WORKDIR $SRC

RUN git clone https://github.com/AFLplusplus/AFLplusplus.git aflplusplus && \
    cd aflplusplus && \
    git checkout c208dcf9c573e3d85990c7dea777646f7fa4961c && \
    wget --no-check-certificate -O oss.sh https://raw.githubusercontent.com/vanhauser-thc/binary_blobs/master/oss.sh && \
    chmod 755 oss.sh    

RUN cd $SRC && \
    curl -L -O https://github.com/google/honggfuzz/archive/oss-fuzz.tar.gz && \
    mkdir honggfuzz && \
    cd honggfuzz && \
    tar -xzv --strip-components=1 -f $SRC/oss-fuzz.tar.gz && \
    rm -rf examples $SRC/oss-fuzz.tar.gz

# Do precompiles before copying other scripts for better cache efficiency.
COPY precompile_afl /usr/local/bin/
RUN precompile_afl

COPY precompile_honggfuzz /usr/local/bin/
RUN precompile_honggfuzz

COPY cargo compile compile_afl compile_dataflow compile_libfuzzer compile_honggfuzz \
    compile_go_fuzzer \
    compile_native_go_fuzzer \
    debug_afl srcmap \
    write_labels.py bazel_build_fuzz_tests \
    # Go, java, and swift installation scripts.
    /usr/local/bin/
COPY llvmsymbol.diff $SRC
COPY detect_repo.py /opt/cifuzz/
COPY bazel.bazelrc /root/.bazelrc

CMD ["compile"]
