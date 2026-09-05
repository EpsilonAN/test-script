#!/usr/bin/env bash
set -e

# =========================================================
# LINEAGEOS 23.2 - MARBLE
# Dolby Vision + Custom Signing
# =========================================================

echo "======================================"
echo "LINEAGEOS 23.2 - MARBLE BUILD"
echo "======================================"

# =========================================================
# 0. CLEAN OLD MANUALLY CLONED TREES
# =========================================================

echo "======================================"
echo "Cleaning old trees"
echo "======================================"

rm -rf device/xiaomi/marble
rm -rf device/xiaomi/sm8450-common
rm -rf vendor/xiaomi/sm8450-common
rm -rf vendor/xiaomi/marble
rm -rf hardware/xiaomi
rm -rf hardware/dolby
rm -rf device/xiaomi/miuicamera-marble
rm -rf vendor/xiaomi/miuicamera-marble
rm -rf kernel/xiaomi/sm8450
rm -rf kernel/xiaomi/sm8450-devicetrees
rm -rf kernel/xiaomi/sm8450-modules
rm -rf device/xiaomi/sepolicy
rm -rf vendor/aosp/signing/keys
rm -rf certs
rm -rf frameworks/av

echo "Clean completed"

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
echo "Installing patched frameworks/av"
echo "======================================"

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

# Verify c91e40b is present
if ! git merge-base --is-ancestor \
    c91e40bc1acc2aefe5fa526f3c58b3fbe3ce5c8b HEAD; then
    echo "ERROR: Dolby commit c91e40b is missing!"
    exit 1
fi

# Verify final Dolby commit d6db6e3 is present
if ! git merge-base --is-ancestor \
    d6db6e3079669cff7cb2d2f956537d6e28b87011 HEAD; then
    echo "ERROR: Dolby commit d6db6e3 is missing!"
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
