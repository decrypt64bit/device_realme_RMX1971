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

# git identity (repo/git refuse to work without it)
git config --global user.name  >/dev/null 2>&1 || git config --global user.name "Axion Builder"
git config --global user.email >/dev/null 2>&1 || git config --global user.email "builder@axion.local"

# git-lfs in user space if the image lacks it
LFS_FLAG="--git-lfs"
if ! command -v git-lfs >/dev/null 2>&1; then
    echo "=== INSTALL GIT-LFS ==="
    mkdir -p "$HOME/bin"
    for v in 3.6.1 3.5.1; do
        curl -fsSL -o /tmp/git-lfs.tgz \
            "https://github.com/git-lfs/git-lfs/releases/download/v$v/git-lfs-linux-amd64-v$v.tar.gz" || continue
        rm -rf /tmp/gitlfs && mkdir -p /tmp/gitlfs
        tar xzf /tmp/git-lfs.tgz -C /tmp/gitlfs || continue
        find /tmp/gitlfs -type f -name git-lfs -exec cp {} "$HOME/bin/git-lfs" \; || continue
        chmod +x "$HOME/bin/git-lfs"
        break
    done
    export PATH="$HOME/bin:$PATH"
    if command -v git-lfs >/dev/null 2>&1; then
        git lfs install --skip-repo || true
    else
        echo "WARN: git-lfs unavailable, continuing without LFS"
        LFS_FLAG=""
    fi
fi
git lfs version 2>/dev/null || true

echo "=== REPO VERSION ==="
repo --version 2>&1 | head -3

echo "=== REPO INIT ==="
repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 $LFS_FLAG --depth=1 --no-clone-bundle

echo "=== LOCAL MANIFEST ==="
mkdir -p .repo/local_manifests
ls -la .repo/local_manifests || true
curl -fsSL "$BASE/local_manifest.xml" -o .repo/local_manifests/rmx1971.xml
cat .repo/local_manifests/rmx1971.xml

echo "=== REPO SYNC ==="
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

echo "=== SYNC DONE $(date -u) ==="
df -h . | tail -1
du -sh .repo 2>/dev/null || true

echo "=== DEVICE TREE CHECK ==="
ls -l device/realme/RMX1971/lineage_RMX1971.mk
ls -l kernel/realme/sdm710/arch/arm64/configs/sdm670-perf_defconfig
ls -l vendor/realme/RMX1971/RMX1971-vendor.mk
ls -l packages/apps/FaceUnlock/common.mk
grep -m1 "^[[:space:]]*<project path=\"packages/apps/FaceUnlock\"" .repo/manifests/snippets/axion.xml || true
git -C packages/apps/FaceUnlock log --oneline -1

echo "=== AXION SYNC READY $(date -u) ==="
