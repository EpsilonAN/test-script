#!/usr/bin/env bash
set -e

# =========================================================
# LINEAGEOS 23.2 - MARBLE
# =========================================================

echo "======================================"
echo "LINEAGEOS 23.2 - MARBLE BUILD"
echo "======================================"

# =========================================================
# 1. INITIALIZE LINEAGEOS SOURCE
# =========================================================

echo "======================================"
echo "Initializing LineageOS 23.2"
echo "======================================"

repo init -u https://github.com/LineageOS/android.git \
  -b lineage-23.2 \
  --git-lfs \
  --depth=1

echo "Repo init successful"

# =========================================================
# 2. SYNC LINEAGEOS SOURCE
# =========================================================

echo "======================================"
echo "Syncing LineageOS source"
echo "======================================"

/opt/crave/resync.sh

echo "LOS source sync successful"

# =========================================================
# 3. DEVICE TREE
# =========================================================

echo "======================================"
echo "Cloning device tree"
echo "======================================"

git clone https://github.com/EpsilonAN/android_device_xiaomi_marble \
  device/xiaomi/marble

git clone https://github.com/EpsilonAN/android_device_xiaomi_sm8450-common \
  device/xiaomi/sm8450-common

# =========================================================
# 4. VENDOR TREES
# =========================================================

echo "======================================"
echo "Cloning vendor trees"
echo "======================================"

git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_sm8450-common \
  vendor/xiaomi/sm8450-common

git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_marble \
  vendor/xiaomi/marble

# =========================================================
# 5. HARDWARE TREES
# =========================================================

echo "======================================"
echo "Cloning hardware trees"
echo "======================================"

git clone https://github.com/EpsilonAN/android_hardware_xiaomi \
  hardware/xiaomi

git clone https://github.com/Dedsec-marble/android_hardware_dolby \
  hardware/dolby

# =========================================================
# 6. MIUI CAMERA
# =========================================================

echo "======================================"
echo "Cloning MIUI camera trees"
echo "======================================"

git clone https://github.com/Dedsec-marble/android_device_xiaomi_miuicamera-marble \
  device/xiaomi/miuicamera-marble

git clone https://github.com/Dedsec-marble/proprietary_vendor_xiaomi_miuicamera-marble \
  vendor/xiaomi/miuicamera-marble

# =========================================================
# 7. KERNEL
# =========================================================

echo "======================================"
echo "Cloning kernel trees"
echo "======================================"

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450 \
  kernel/xiaomi/sm8450

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-devicetrees \
  kernel/xiaomi/sm8450-devicetrees

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-modules \
  kernel/xiaomi/sm8450-modules

# =========================================================
# 8. SEPOLICY
# =========================================================

echo "======================================"
echo "Cloning Xiaomi sepolicy"
echo "======================================"

git clone https://github.com/AOSPA/android_device_xiaomi_sepolicy \
  device/xiaomi/sepolicy

echo "======================================"
echo "All device/vendor/hardware/kernel trees cloned"
echo "======================================"

# =========================================================
# 9. SIGNING CERTIFICATES
# =========================================================

echo "======================================"
echo "Cloning signing certificates"
echo "======================================"

git clone https://github.com/xenxynon/certs \
  vendor/aosp/signing/keys

git clone https://github.com/xenxynon/certs

echo "Signing certificates cloned successfully"

# =========================================================
# 10. PATCHED FRAMEWORKS/AV
# =========================================================

echo "======================================"
echo "Replacing default frameworks/av"
echo "======================================"

rm -rf frameworks/av

git clone -b lineage-23.2 \
  https://github.com/EpsilonAN/android_frameworks_av.git \
  frameworks/av

echo "Patched frameworks/av cloned successfully"

# =========================================================
# 11. VERIFY FRAMEWORKS/AV
# =========================================================

echo "======================================"
echo "Verifying patched frameworks/av"
echo "======================================"

cd frameworks/av

echo "Current branch:"
git branch --show-current

echo "Latest commits:"
git log -8 --oneline

# Check for unresolved merge conflicts
if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "ERROR: Unresolved merge conflicts found in frameworks/av"
    git status
    exit 1
fi

# Verify Dolby commit 1
if ! git log --oneline -20 | grep -q \
    "libstagefright: omx: Add support for loading prebuilt ddp and ac4 decoder lib"; then
    echo "ERROR: Dolby commit 1 is missing!"
    exit 1
fi

# Verify Dolby commit 2
if ! git log --oneline -20 | grep -q \
    "OMX: Remove support for prebuilt ac4 decoder"; then
    echo "ERROR: Dolby commit 2 is missing!"
    exit 1
fi

# Verify Dolby commit 3
if ! git log --oneline -20 | grep -q \
    "media: OMXStore: Import loading libstagefrightdolby"; then
    echo "ERROR: Dolby commit 3 is missing!"
    exit 1
fi

# Verify Dolby commit 4
if ! git log --oneline -20 | grep -q \
    "media: Add changes to pick target specific media xml"; then
    echo "ERROR: Dolby commit 4 is missing!"
    exit 1
fi

# Verify Dolby commit 5
if ! git log --oneline -20 | grep -q \
    "MediaProfiles: Check before overriding media settings xml"; then
    echo "ERROR: Dolby commit 5 is missing!"
    exit 1
fi

echo "Dolby framework commits verified successfully"

cd ../..

# =========================================================
# 12. BUILD CONFIGURATION
# =========================================================

echo "======================================"
echo "Preparing build environment"
echo "======================================"

export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export GIT_EDITOR=true

source build/envsetup.sh

lunch lineage_marble-bp4a-userdebug

echo "Build environment ready"

# =========================================================
# 13. BUILD LINEAGEOS
# =========================================================

echo "======================================"
echo "STARTING LINEAGEOS 23.2 BUILD"
echo "======================================"

m bacon

echo "======================================"
echo "LineageOS bacon build completed"
echo "======================================"

# =========================================================
# 14. BUILD TARGET FILES + OTA TOOLS
# =========================================================

echo "======================================"
echo "Building target-files and OTA tools"
echo "======================================"

m target-files-package otatools

echo "Target-files and OTA tools completed"

# =========================================================
# 15. DETECT TARGET-FILES ZIP
# =========================================================

echo "======================================"
echo "Searching for target-files ZIP"
echo "======================================"

TARGET_FILES_ZIP=$(find out/target/product \
  -type f \
  -name "*-target_files.zip" \
  | head -n 1)

if [ -z "$TARGET_FILES_ZIP" ]; then
    echo "ERROR: target-files ZIP not found!"
    echo "Build/signing cannot continue."
    exit 1
fi

echo "======================================"
echo "TARGET FILES FOUND"
echo "$TARGET_FILES_ZIP"
echo "======================================"

# =========================================================
# 16. SIGN TARGET FILES
# =========================================================

echo "======================================"
echo "Signing target-files"
echo "======================================"

sign_target_files_apks \
  -o \
  -d vendor/aosp/signing/keys \
  "$TARGET_FILES_ZIP" \
  signed-target_files.zip

echo "Target-files signed successfully"

# =========================================================
# 17. GENERATE SIGNED OTA
# =========================================================

echo "======================================"
echo "Generating signed OTA"
echo "======================================"

ota_from_target_files \
  -k vendor/aosp/signing/keys/releasekey \
  signed-target_files.zip \
  signed-ota_update.zip

echo "Signed OTA generated successfully"

# =========================================================
# 18. FINAL OUTPUT
# =========================================================

echo "======================================"
echo "BUILD + SIGNING COMPLETE"
echo "======================================"

echo "Signed target-files:"
ls -lh signed-target_files.zip

echo "Signed OTA:"
ls -lh signed-ota_update.zip

echo "======================================"
echo "LINEAGEOS 23.2 MARBLE BUILD FINISHED"
echo "======================================"
