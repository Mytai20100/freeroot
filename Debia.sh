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

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#                                                                                     #"
  echo "#                                      Proot INSTALLER                                #"
  echo "#                                                                                     #"
  echo "#                                    Copyright (C) 2024                               #"
  echo "#                                                                                     #"
  echo "#                                                                                     #"
  echo "#######################################################################################"

  read -p "Do you want to install Debian? (YES/no): " install_debian
fi

case $install_debian in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "https://deb.debian.org/debian/dists/bullseye/main/installer-${ARCH_ALT}/current/images/netboot/mini.iso"
    if [ -f /tmp/rootfs.tar.gz ]; then
      tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
    else
      echo "Failed to download the Debian image."
      exit 1
    fi
    ;;
  *)
    echo "Skipping Debian installation."
    ;;
esac

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" \
    "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf "$ROOTFS_DIR/usr/local/bin/proot"
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" \
      "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
      break
    fi

    sleep 1
  done
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -rf /tmp/rootfs.tar.gz /tmp/sbin
  touch "$ROOTFS_DIR/.installed"
fi

# Ensure /bin/sh exists in the root filesystem
if [ ! -f "$ROOTFS_DIR/bin/sh" ]; then
  echo "Installing /bin/sh (bash)"
  mkdir -p "$ROOTFS_DIR/bin"
  ln -s /usr/bin/bash "$ROOTFS_DIR/bin/sh"
fi

# Ensure /root exists
if [ ! -d "$ROOTFS_DIR/root" ]; then
  mkdir -p "$ROOTFS_DIR/root"
fi

# Install bash if it's not present in rootfs
if [ ! -f "$ROOTFS_DIR/usr/bin/bash" ]; then
  echo "Installing bash in rootfs"
  apt-get update
  apt-get install -y bash
fi

# Get system information
cpu_info=$(lscpu | grep "Model name:" | awk -F: '{print $2}' | xargs)
ram_info=$(free -h | grep "Mem:" | awk '{print $2}')
disk_info=$(df -h "$ROOTFS_DIR" | grep -v "Filesystem" | awk '{print $2}')

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

# Display system information
echo -e "${WHITE}System Information:${RESET_COLOR}"
echo -e "CPU Model: ${cpu_info}"
echo -e "Total RAM: ${ram_info}"
echo -e "Disk Size: ${disk_info}"

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

# Set execute permission
chmod +x "$ROOTFS_DIR/usr/local/bin/proot"
if [ $? -ne 0 ]; then
  echo "Failed to set execute permission for proot. Please check your permissions or run this script with 'sudo'."
  exit 1
fi

# Run proot
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
