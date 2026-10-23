#!/usr/bin/env bash
# AxionOS build for Realme 5 Pro (RMX1971) on Crave.
# Run from the Crave project workspace root after sync.sh.
set -euo pipefail

echo "=== AXION BUILD START $(date -u) ==="
echo "PWD=$(pwd)"
df -h . | tail -1

export LC_ALL=C

set +u
source build/envsetup.sh
set -u

echo "=== KEYS ==="
gk -s

echo "=== LUNCH ==="
axion RMX1971 userdebug va

echo "=== BUILD ==="
ax -br -j"$(nproc)"

echo "=== BUILD OUTPUT ==="
ls -lh out/target/product/RMX1971/axion-*.zip
sha256sum out/target/product/RMX1971/axion-*.zip

echo "=== AXION BUILD DONE $(date -u) ==="
