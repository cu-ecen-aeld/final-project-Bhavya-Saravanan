#!/bin/bash
# Script to build Yocto image for Raspberry Pi 4 with Wi-Fi and Mender enabled
# Author: Vrushabh Gada (Fixed Version)

set -e

echo "=== Initializing submodules ==="
git submodule init
git submodule sync
git submodule update

echo "=== Setting up build environment ==="
source poky/oe-init-build-env

CONF_FILE="conf/local.conf"

# --- Ensure local.conf exists ---
if [ ! -f "$CONF_FILE" ]; then
    echo "Error: local.conf not found. Make sure build environment is set correctly."
    exit 1
fi

# --- Clean up old config ---
echo "=== Cleaning old configuration ==="
sed -i '/INHERIT.*mender/d' "$CONF_FILE"
sed -i '/MENDER_/d' "$CONF_FILE"
sed -i '/^MACHINE =/d' "$CONF_FILE"
sed -i '/IMAGE_FSTYPES/d' "$CONF_FILE"
sed -i '/SDIMG_ROOTFS_TYPE/d' "$CONF_FILE"
sed -i '/^GPU_MEM/d' "$CONF_FILE"
sed -i '/DISTRO_FEATURES.*wifi/d' "$CONF_FILE"
sed -i '/VIRTUAL-RUNTIME_init_manager/d' "$CONF_FILE"
sed -i '/DISTRO_FEATURES_BACKFILL/d' "$CONF_FILE"
sed -i '/IMAGE_FEATURES.*ssh/d' "$CONF_FILE"
sed -i '/IMAGE_INSTALL:append/d' "$CONF_FILE"
sed -i '/ENABLE_UART/d' "$CONF_FILE"
sed -i '/SERIAL_CONSOLES/d' "$CONF_FILE"
sed -i '/RPI_EXTRA_CONFIG/d' "$CONF_FILE"
sed -i '/RPI_USE_U_BOOT/d' "$CONF_FILE"
sed -i '/PREFERRED_PROVIDER_virtual\/bootloader/d' "$CONF_FILE"

# --- Add Layers ---
add_layer_if_missing() {
    local layer_path="$1"
    local layer_name
    layer_name=$(basename "$layer_path")
    if ! bitbake-layers show-layers | grep -q "$layer_name"; then
        echo "Adding layer: $layer_path"
        bitbake-layers add-layer "$layer_path"
    else
        echo "Layer $layer_name already exists"
    fi
}

echo "=== Adding required layers ==="
add_layer_if_missing "../meta-openembedded/meta-oe"
add_layer_if_missing "../meta-openembedded/meta-python"
add_layer_if_missing "../meta-openembedded/meta-networking"
add_layer_if_missing "../meta-raspberrypi"
add_layer_if_missing "../meta-mender/meta-mender-core"
add_layer_if_missing "../meta-mender/meta-mender-raspberrypi"
add_layer_if_missing "../meta-custom"

# --- Append config helper ---
append_config() {
    local line="$1"
    echo "Adding: $line"
    echo "$line" >> "$CONF_FILE"
}

echo "=== Writing new configuration ==="

# Basic RPi Config
append_config 'MACHINE = "raspberrypi4-64"' "$CONF_FILE"
append_config 'GPU_MEM = "16"' "$CONF_FILE"
append_config 'RPI_USE_U_BOOT = "1"' "$CONF_FILE"
append_config 'PREFERRED_PROVIDER_virtual/bootloader = "u-boot"' "$CONF_FILE"
append_config 'ENABLE_UART = "1"' "$CONF_FILE"
append_config 'RPI_EXTRA_CONFIG = "hdmi_force_hotplug=1"' "$CONF_FILE"
append_config 'SERIAL_CONSOLES = "115200;ttyS0"' "$CONF_FILE"

# Systemd + WiFi support
append_config 'DISTRO_FEATURES:append = " wifi systemd"' "$CONF_FILE"
append_config 'VIRTUAL-RUNTIME_init_manager = "systemd"' "$CONF_FILE"
append_config 'DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"' "$CONF_FILE"
append_config 'IMAGE_FEATURES += "ssh-server-openssh"' "$CONF_FILE"

# WiFi packages + your wpa-supplicant config recipe
append_config 'IMAGE_INSTALL:append = " linux-firmware-rpidistro-bcm43455 wpa-supplicant kernel-modules dhcpcd iw iproute2 packagegroup-base wpa-supplicant-config"' "$CONF_FILE"

# Mender Core
append_config 'INHERIT += "mender-full"' "$CONF_FILE"
append_config 'MENDER_FEATURES_ENABLE:append = " mender-uboot mender-image mender-systemd"' "$CONF_FILE"
append_config 'MENDER_FEATURES_DISABLE:append = " mender-grub mender-image-uefi"' "$CONF_FILE"

# Mender Device
append_config 'MENDER_DEVICE_TYPE = "raspberrypi4"' "$CONF_FILE"
append_config 'MENDER_ARTIFACT_NAME = "release-1"' "$CONF_FILE"

# Mender Partition Setup
append_config 'MENDER_STORAGE_DEVICE = "/dev/mmcblk0"' "$CONF_FILE"
append_config 'MENDER_BOOT_PART = "/dev/mmcblk0p1"' "$CONF_FILE"
append_config 'MENDER_ROOTFS_PART_A = "/dev/mmcblk0p2"' "$CONF_FILE"
append_config 'MENDER_ROOTFS_PART_B = "/dev/mmcblk0p3"' "$CONF_FILE"
append_config 'MENDER_DATA_PART = "/dev/mmcblk0p4"' "$CONF_FILE"

append_config 'MENDER_STORAGE_TOTAL_SIZE_MB = "8192"' "$CONF_FILE"
append_config 'MENDER_BOOT_PART_SIZE_MB = "256"' "$CONF_FILE"
append_config 'MENDER_DATA_PART_SIZE_MB = "1024"' "$CONF_FILE"

# Mender Server
append_config 'MENDER_SERVER_URL = "https://hosted.mender.io"' "$CONF_FILE"
append_config 'MENDER_TENANT_TOKEN = "IEeJCwBlnKUMwWenQTZvV7W12yKs3yee8rTz_VVpeCY"' "$CONF_FILE" 
append_config 'MENDER_UPDATE_POLL_INTERVAL_SECONDS = "1800"' "$CONF_FILE"

# Build BOTH .sdimg and .mender
append_config 'IMAGE_FSTYPES += " rpi-sdimg mender"' "$CONF_FILE"
append_config 'SDIMG_ROOTFS_TYPE = "ext4"' "$CONF_FILE"

echo ""
echo "=== Final local.conf preview ==="
grep -E "(MACHINE|IMAGE_FSTYPES|wifi|wpa|mender)" "$CONF_FILE"
echo ""

echo "=== Building image (this takes time) ==="
bitbake core-image-minimal

echo ""
echo "=== Build Complete ==="
echo "Image location: tmp/deploy/images/raspberrypi4-64/"
echo ""
echo "Look for these files:"
echo "  - core-image-minimal-raspberrypi4-64.rpi-sdimg (flashable SD card image)"
echo "  - core-image-minimal-raspberrypi4-64.mender (update artifact)"
echo ""
echo "To flash the Mender image to SD card:"
echo "  cd build/tmp/deploy/images/raspberrypi4-64/"
echo "  sudo dd if=core-image-minimal-raspberrypi4-64.rpi-sdimg of=/dev/sdb bs=4M status=progress conv=fsync"
echo "  sync; sync; sync"
echo "  sudo eject /dev/sdb"



