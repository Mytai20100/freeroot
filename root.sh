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

# Chọn hệ điều hành rootfs
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                   RootFS INSTALLER"
  echo "#"
  echo "#                                  Copyright (C) 2024
  echo "#"
  echo "#######################################################################################"

  echo "Please select the OS you want to install:"
  echo "1) Ubuntu 20.04"
  echo "2) Debian 11"
  echo "3) Arch Linux"
  read -p "Enter your choice (1/2/3): " os_choice
fi

# Tải root filesystem dựa trên lựa chọn của người dùng
case $os_choice in
  1)
    os_name="Ubuntu"
    rootfs_url="http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    ;;
  2)
    os_name="Debian"
    rootfs_url="https://deb.debian.org/debian/dists/bullseye/main/installer-${ARCH_ALT}/current/images/netboot/mini.iso"
    ;;
  3)
    os_name="Arch Linux"
    rootfs_url="https://archive.archlinux.org/iso/2023.04.01/archlinux-bootstrap-2023.04.01-${ARCH_ALT}.tar.gz"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# Cài đặt rootfs
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "Installing ${os_name} rootfs..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz "$rootfs_url"
  tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
fi

# Cài đặt proot
if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Mytai20100x/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf $ROOTFS_DIR/usr/local/bin/proot
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    sleep 1
  done
  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Thiết lập DNS và đánh dấu hoàn tất cài đặt
if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.gz
  touch $ROOTFS_DIR/.installed
fi

# Lấy thông tin hệ thống
cpu_info=$(lscpu | grep "Model name:" | awk -F: '{print $2}' | xargs)
ram_info=$(free -h | grep "Mem:" | awk '{print $2}')
disk_info=$(df -h $ROOTFS_DIR | grep -v "Filesystem" | awk '{print $2}')

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

# Hiển thị thông tin hệ thống
echo -e "${WHITE}System Information:${RESET_COLOR}"
echo -e "CPU Model: ${cpu_info}"
echo -e "Total RAM: ${ram_info}"
echo -e "Disk Size: ${disk_info}"

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Installation Completed! <----${RESET_COLOR}"
}

clear
display_gg

# Khởi chạy Proot với rootfs của hệ điều hành được chọn
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
  /bin/bash
