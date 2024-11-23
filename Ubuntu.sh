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
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#                                                                                     #"
  echo "#                                      Proot INSTALLER                                #"
  echo "#                                                                                     #"
  echo "#                                    Copyright (C) 2024                               #"
  echo "#                                                                                     #"
  echo "#                                                                                     #"
  echo "#######################################################################################"

  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir $ROOTFS_DIR/usr/local/bin -p
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.installed
fi

GREEN="\033[0;32m"
YELLOW="\033[0;33m"-e
RED="\033[0;31m"
RESET="\033[0m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
RESET_COLOR="\033[0m"

# Lấy thông tin hệ thống
OS_VERSION=$(lsb_release -ds 2>/dev/null || echo "N/A")
CPU_NAME=$(lscpu | awk -F: '/Model name:/ {print $2}' | sed 's/^ //')
CPU_ARCH=$(uname -m)
CPU_USAGE=$(top -bn1 | awk '/Cpu\(s\)/ {print $2 + $4}')
TOTAL_RAM=$(free -h --si | awk '/^Mem:/ {print $2}')
USED_RAM=$(free -h --si | awk '/^Mem:/ {print $3}')
DISK_SPACE=$(df -h / | awk 'NR==2 {print $2}')
USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
PORTS=$(ss -tunlp | wc -l)
IP_ADDRESS=$(hostname -I | awk '{print $1}')


display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

display_version() {
  echo -e "${WHITE}_______________________________________________________________________${RESET_COLOR}"
  echo -e "${CYAN}OS:${RESET} $OS_VERSION"
  echo -e "${CYAN}CPU:${RESET} $CPU_NAME [$CPU_ARCH]"
  echo -e "${CYAN}Used CPU:${RESET} ${CPU_USAGE}%"
  echo -e "${GREEN}RAM:${RESET} $USED_RAM / $TOTAL_RAM"
  echo -e "${YELLOW}Disk:${RESET} $USED_DISK / $DISK_SPACE"
  echo -e "${RED}Ports:${RESET} $PORTS"
  echo -e "${RED}IP:${RESET} $IP_ADDRESS"
  echo -e "${WHITE}_______________________________________________________________________${RESET_COLOR}"
}

clear
display_version
echo  ""
display_gg

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
