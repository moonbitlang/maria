#!/bin/bash
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Run expensive tests that are too slow or resource-intensive for regular CI.
# This script is triggered by commenting `/run-expensive-tests` on a PR.

set -e

echo "=== Running Expensive Tests ==="
echo "Starting at: $(date)"

# Build the project in release mode
echo ""
echo "Building project in release mode..."
moon build --release

# Run all tests including skipped ones (expensive tests)
echo ""
echo "Running all tests (including skipped/expensive tests)..."
moon test --include-skipped -v

echo ""
echo "=== Expensive Tests Complete ==="
echo "Finished at: $(date)"
