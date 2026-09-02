#!/usr/bin/env bash

=========================================================

REPO INIT

=========================================================

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs

echo "=================="
echo "Repo init success"
echo "=================="

=========================================================

BUILD SYNC

=========================================================

/opt/crave/resync.sh

echo "============="
echo "Sync success"
echo "============="

=========================================================

DEVICE / VENDOR / HARDWARE / KERNEL TREES

=========================================================

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

=========================================================

SIGNING KEYS

=========================================================

git clone https://github.com/xenxynon/certs vendor/aosp/signing/keys

git clone https://github.com/xenxynon/certs

echo "======================================"
echo "All trees and signing keys ready"
echo "======================================"

=========================================================

EXPORT

=========================================================

export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true

echo "======= Export Done ======="

=========================================================

BUILD ENVIRONMENT

=========================================================

source build/envsetup.sh

echo "==========================="
echo "Build environment ready"
echo "==========================="

=========================================================

LUNCH

=========================================================

lunch lineage_marble-bp4a-userdebug

=========================================================

BUILD

=========================================================

echo "======================================"
echo "Starting LineageOS build"
echo "======================================"

m bacon

=========================================================

CREATE TARGET FILES + OTA TOOLS

=========================================================

echo "======================================"
echo "Creating target-files and OTA tools"
echo "======================================"

m target-files-package otatools

=========================================================

SIGN TARGET FILES

=========================================================

echo "======================================"
echo "Signing target-files"
echo "======================================"

sign_target_files_apks -o -d vendor/aosp/signing/keys 
out/target/product/marble/obj/PACKAGING/target_files_intermediates/target_files.zip 
signed-target_files.zip

=========================================================

CREATE SIGNED OTA

=========================================================

echo "======================================"
echo "Creating signed OTA"
echo "======================================"

ota_from_target_files -k vendor/aosp/signing/keys/releasekey 
signed-target_files.zip 
signed-ota_update.zip

=========================================================

OUTPUT

=========================================================

echo "======================================"
echo "BUILD + SIGNING COMPLETED"
echo "======================================"

ls -lh signed-target_files.zip
ls -lh signed-ota_update.zip

ls -lh out/target/product/marble

echo "======================================"
echo "All files ready"
echo "======================================"