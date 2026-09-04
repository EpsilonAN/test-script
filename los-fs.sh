#!/usr/bin/env bash

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1
/opt/crave/resync.sh

git clone https://github.com/EpsilonAN/android_device_xiaomi_marble device/xiaomi/marble
git clone https://github.com/EpsilonAN/android_device_xiaomi_sm8450-common device/xiaomi/sm8450-common
git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_sm8450-common vendor/xiaomi/sm8450-common
git clone https://github.com/EpsilonAN/proprietary_vendor_xiaomi_marble vendor/xiaomi/marble
git clone https://github.com/EpsilonAN/android_hardware_xiaomi hardware/xiaomi
git clone https://github.com/Dedsec-marble/android_hardware_dolby hardware/dolby
git clone https://github.com/Dedsec-marble/android_device_xiaomi_miuicamera-marble device/xiaomi/miuicamera-marble
git clone https://github.com/Dedsec-marble/proprietary_vendor_xiaomi_miuicamera-marble vendor/xiaomi/miuicamera-marble
git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450 kernel/xiaomi/sm8450
git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-devicetrees kernel/xiaomi/sm8450-devicetrees
git clone https://github.com/EpsilonAN/android_kernel_xiaomi_sm8450-modules kernel/xiaomi/sm8450-modules
git clone https://github.com/AOSPA/android_device_xiaomi_sepolicy device/xiaomi/sepolicy
git clone https://github.com/xenxynon/certs vendor/aosp/signing/keys

export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true

source build/envsetup.sh
lunch lineage_marble-bp4a-userdebug

m bacon
m target-files-package otatools

sign_target_files_apks -o -d vendor/aosp/signing/keys \
out/target/product/marble/obj/PACKAGING/target_files_intermediates/*target_files*.zip \
signed-target_files.zip

ota_from_target_files -k vendor/aosp/signing/keys/releasekey \
signed-target_files.zip \
signed-ota_update.zip

ls -lh signed-target_files.zip signed-ota_update.zip
