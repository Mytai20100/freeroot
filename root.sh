#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# Chạy tập lệnh Ubuntu.sh theo lựa chọn của người dùng
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                   RootFS INSTALLER"
  echo "#"
  echo "#                                  Copyright (C) 2024"
  echo "#"
  echo "#######################################################################################"

  echo "Please select the OS you want to install:"
  echo "1) Ubuntu 20.04"
  echo "2) Debian 11"
  echo "3) Arch Linux"
  read -p "Enter your choice (1/2/3): " os_choice

  case $os_choice in
    1)
      echo "Launching Ubuntu installation script..."
      sh ./Ubuntu.sh
      ;;
    2)
      echo "Launching Debia installation script...."
      sh ./Debia.sh
      ;;
    3)
      echo "Launching Arch installation script...."
      sh ./Arch.sh
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi
