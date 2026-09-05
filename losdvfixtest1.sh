#!/usr/bin/env bash
set -e

# =========================================================
# LINEAGEOS 23.2 - MARBLE
# =========================================================

# =========================================================
# 0. Clean old trees
# =========================================================

echo "======================================"
echo "Cleaning"
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

echo "======================================"
echo "Clean completed"
echo "======================================"

# =========================================================
# 1. Initial LOS source
# =========================================================

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

echo "======================================"
echo "Repo init successful"
echo "======================================"

# =========================================================
# 2. Sync LOS source
# =========================================================

/opt/crave/resync.sh

echo "======================================"
echo "LOS source sync successful"
echo "======================================"

# =========================================================
# 3. Device / Vendor / Hardware / Kernel
# =========================================================

git clone https://github.com/EpsilonAN/android_device_xiaomi_marble \
  device/xiaomi/marble

git clone https://github.com/EpsilonAN/android_device_xiaomi_sm8450-common \
  device/xiaomi/sm8450-common

git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_sm8450-common \
  vendor/xiaomi/sm8450-common

git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_marble \
  vendor/xiaomi/marble

git clone https://github.com/EpsilonAN/android_hardware_xiaomi \
  hardware/xiaomi

git clone https://github.com/Dedsec-marble/android_hardware_dolby \
  hardware/dolby

git clone https://github.com/Dedsec-marble/android_device_xiaomi_miuicamera-marble \
  device/xiaomi/miuicamera-marble

git clone https://github.com/Dedsec-marble/proprietary_vendor_xiaomi_miuicamera-marble \
  vendor/xiaomi/miuicamera-marble

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450 \
  kernel/xiaomi/sm8450

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-devicetrees \
  kernel/xiaomi/sm8450-devicetrees

git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-modules \
  kernel/xiaomi/sm8450-modules

git clone https://github.com/AOSPA/android_device_xiaomi_sepolicy \
  device/xiaomi/sepolicy

echo "======================================"
echo "All device trees cloned successfully"
echo "======================================"

# =========================================================
# 4. Signing certificates
# =========================================================

git clone https://github.com/xenxynon/certs \
  vendor/aosp/signing/keys

git clone https://github.com/xenxynon/certs

echo "======================================"
echo "Signing certificates cloned"
echo "======================================"

# =========================================================
# 5. Dolby Vision - frameworks/av
# =========================================================

echo "======================================"
echo "Applying Dolby Vision framework fixes"
echo "======================================"

cd frameworks/av

git fetch https://github.com/cr-15-temp/frameworks_av.git vili

# Dolby Vision patchset

git cherry-pick 77911c405d31eeee685dd5a63d67c0d621c43dc3
git cherry-pick ac00328b58f581a90cca2dd59a77fc7aaab9fcd9
git cherry-pick c249181b0be624b2d3bbb9d895311335343aaa7d
git cherry-pick c91e40bc1acc2aefe5fa526f3c58b3fbe3ce5c8b
git cherry-pick d6db6e3079669cff7cb2d2f956537d6e28b87011

cd ../..

echo "======================================"
echo "Dolby Vision patches applied"
echo "======================================"

# =========================================================
# 6. Build configuration
# =========================================================

export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true

source build/envsetup.sh

lunch lineage_marble-bp4a-userdebug

# =========================================================
# 7. Build
# =========================================================

echo "======================================"
echo "Starting LOS 23.2 build"
echo "======================================"

m bacon
m target-files-package otatools

# =========================================================
# 8. Find target-files ZIP
# =========================================================

TARGET_FILES_ZIP=$(find out/target/product \
  -name "*-target_files.zip" \
  -type f | head -n 1)

if [ -z "$TARGET_FILES_ZIP" ]; then
    echo "Error: target-files ZIP not found!"
    echo "Build might have failed."
    exit 1
fi

echo "======================================"
echo "Target files found:"
echo "$TARGET_FILES_ZIP"
echo "======================================"

# =========================================================
# 9. Sign target files
# =========================================================

sign_target_files_apks \
  -o \
  -d vendor/aosp/signing/keys \
  "$TARGET_FILES_ZIP" \
  signed-target_files.zip

# =========================================================
# 10. Generate signed OTA
# =========================================================

ota_from_target_files \
  -k vendor/aosp/signing/keys/releasekey \
  signed-target_files.zip \
  signed-ota_update.zip

# =========================================================
# 11. Final output
# =========================================================

echo "======================================"
echo "BUILD + SIGNING COMPLETE"
echo "======================================"

ls -lh signed-target_files.zip signed-ota_update.zip
