#!/usr/bin/env bash
# AxionOS sync for Realme 5 Pro (RMX1971) on Crave.
# Run from the Crave project workspace root: curl -fsSL <raw-url>/sync.sh | bash
set -euo pipefail

BASE="https://raw.githubusercontent.com/decrypt64bit/device_realme_RMX1971/axion-16/ci"

echo "=== AXION SYNC START $(date -u) ==="
echo "PWD=$(pwd)"
df -h . | tail -1
echo "CPUS=$(nproc) MEM_GB=$(free -g | awk '/^Mem:/{print $2}')"

avail=$(df -BG --output=avail . | tail -1 | tr -dc '0-9')
echo "AVAIL_GB=$avail"
if [ "${avail:-0}" -lt 120 ]; then
    echo "ABORT: less than 120G free"
    exit 1
fi

echo "=== REPO INIT ==="
repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --git-lfs --depth=1 --no-clone-bundle

echo "=== LOCAL MANIFEST ==="
mkdir -p .repo/local_manifests
curl -fsSL "$BASE/local_manifest.xml" -o .repo/local_manifests/rmx1971.xml
cat .repo/local_manifests/rmx1971.xml

echo "=== REPO SYNC ==="
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

echo "=== SYNC DONE $(date -u) ==="
df -h . | tail -1
du -sh .repo 2>/dev/null || true

echo "=== PROTON CLANG ==="
CLANG_DIR=prebuilts/clang/host/linux-x86/clang-proton
if [ ! -x "$CLANG_DIR/bin/clang" ]; then
    rm -rf "$CLANG_DIR"
    git clone --depth=1 https://github.com/kdrag0n/proton-clang.git "$CLANG_DIR"
fi
"$CLANG_DIR/bin/clang" --version | head -2

echo "=== DEVICE TREE CHECK ==="
ls device/realme/RMX1971/lineage_RMX1971.mk
ls kernel/realme/sdm710/arch/arm64/configs/sdm670-perf_defconfig
ls vendor/realme/RMX1971/RMX1971-vendor.mk
ls packages/apps/FaceUnlock/common.mk

echo "=== AXION SYNC READY $(date -u) ==="
