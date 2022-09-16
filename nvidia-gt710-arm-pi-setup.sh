#!/bin/bash

# Attempt to set up the Nvidia GeForce GT 710 on a Pi CM4.
#
# I have tried both armv7l and aarch64 versions of the proprietary driver, in
# addition to the nouveau open source driver (which needs to be compiled into
# a custom Raspberry Pi kernel).
#
# tl;dr - None of the drivers worked :P

# First, expand the BAR space, following the directions in this gist:
# https://gist.github.com/geerlingguy/9d78ea34cab8e18d71ee5954417429df

#####
# Option A - Proprietary Driver
#####

# Install kernel-headers so kernel module can be built.
sudo apt-get update
sudo apt upgrade -y   # if necessary
sudo reboot           # if necessary
sudo apt install -y raspberrypi-kernel-headers

# Download driver from Nvidia's website.
# 32-bit: https://www.nvidia.com/en-us/drivers/unix/linux-arm-display-archive/
# wget https://us.download.nvidia.com/XFree86/Linux-x86-ARM/390.138/NVIDIA-Linux-armv7l-gnueabihf-390.138.run
# 64-bit: https://www.nvidia.com/en-us/drivers/unix/linux-aarch64-archive/
wget https://us.download.nvidia.com/XFree86/aarch64/455.28/NVIDIA-Linux-aarch64-455.28.run
# TODO: Any way to get the latest version and get the download URL in a script? Manual download is sooo annoying.

# (If running) stop X server.
sudo systemctl stop lightdm

# Run the driver .run file we just downloaded.
chmod +x ./NVIDIA-Linux-aarch64-455.28.run
sudo ./NVIDIA-Linux-aarch64-455.28.run
# For 32-bit: sudo ./NVIDIA-Linux-armv7l-gnueabihf-390.138.run --kernel-source-path /usr/src/linux-headers-5.4.51-v7l+

# Reboot and (sadly) see the card fail to initialize.
sudo reboot

#####
# Option B - compile nouveau module into custom Pi Kernel
#####

# Install dependencies
sudo apt install -y git bc bison flex libssl-dev make

# Clone source
git clone --depth=1 https://github.com/raspberrypi/linux

# Apply default configuration
cd linux
export KERNEL=kernel7l # use kernel8 for 64-bit, or kernel7l for 32-bit
make bcm2711_defconfig

# Customize the .config further with menuconfig
sudo apt install -y libncurses5-dev
make menuconfig
# (search for /nouveau, enable in the proper section, save, then exit)
nano .config
# (edit CONFIG_LOCALVERSION and add a suffix that helps you identify your build)

# Build the kernel and copy everything into place
make -j4 zImage modules dtbs # 'Image' on 64-bit
sudo make modules_install
sudo cp arch/arm/boot/dts/*.dtb /boot/
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
sudo cp arch/arm/boot/zImage /boot/$KERNEL.img

# Reboot, but it locks up if you have the card in :(
sudo reboot