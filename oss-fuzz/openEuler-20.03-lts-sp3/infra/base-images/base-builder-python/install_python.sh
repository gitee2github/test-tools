#!/bin/bash -eux
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

echo "ATHERIS INSTALL"
unset CFLAGS CXXFLAGS
pip3 install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -v --no-cache-dir "atheris>=2.0.6" "pyinstaller==5.0.1" "coverage==6.3.2" -i https://pypi.tuna.tsinghua.edu.cn/simple
rm -rf /tmp/*
