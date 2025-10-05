#!/bin/sh
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)
case "$ARCH" in
x86_64)ARCH_ALT=amd64;;
aarch64)ARCH_ALT=arm64;;
*)printf "Unsupported CPU: ${ARCH}\n";exit 1;;
esac
if [ ! -e $ROOTFS_DIR/.installed ];then
echo "###################################################################"
echo "#              Proot INSTALLER - Copyright (C) 2024              #"
echo "###################################################################"
wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
"http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04-base-${ARCH_ALT}.tar.gz"
tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR 2>/dev/null
mkdir -p $ROOTFS_DIR/usr/local/bin
wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
"https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"
while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ];do
rm -rf $ROOTFS_DIR/usr/local/bin/proot
wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
"https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"
[ -s "$ROOTFS_DIR/usr/local/bin/proot" ]&&chmod 755 $ROOTFS_DIR/usr/local/bin/proot&&break
sleep 1
done
chmod 755 $ROOTFS_DIR/usr/local/bin/proot
mkdir -p $ROOTFS_DIR/root
printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n">${ROOTFS_DIR}/etc/resolv.conf
[ ! -e $ROOTFS_DIR/bin/sh ]&&ln -sf /usr/bin/bash $ROOTFS_DIR/bin/sh 2>/dev/null
rm -rf /tmp/rootfs.tar.gz /tmp/sbin
touch $ROOTFS_DIR/.installed
fi
G="\033[0;32m"
Y="\033[0;33m"
R="\033[0;31m"
C="\033[0;36m"
W="\033[0;37m"
X="\033[0m"
OS=$(lsb_release -ds 2>/dev/null||echo "N/A")
CPU=$(lscpu|awk -F: '/Model name:/{print $2}'|sed 's/^ //')
ARCH_D=$(uname -m)
CPU_U=$(top -bn1|awk '/Cpu\(s\)/{print $2+$4}')
TRAM=$(free -h --si|awk '/^Mem:/{print $2}')
URAM=$(free -h --si|awk '/^Mem:/{print $3}')
DISK=$(df -h /|awk 'NR==2{print $2}')
UDISK=$(df -h /|awk 'NR==2{print $3}')
PORTS=$(ss -tunlp 2>/dev/null|wc -l)
IP=$(hostname -I|awk '{print $1}')
clear
echo -e "${W}_______________________________________________________________________${X}"
echo -e "${C}OS:${X} $OS"
echo -e "${C}CPU:${X} $CPU [$ARCH_D] ${CPU_U}%"
echo -e "${G}RAM:${X} $URAM / $TRAM"
echo -e "${Y}Disk:${X} $UDISK / $DISK"
echo -e "${R}Ports:${X} $PORTS"
echo -e "${R}IP:${X} $IP"
echo -e "${W}_______________________________________________________________________${X}"
echo ""
echo -e "${W}___________________________________________________${X}"
echo -e "           ${C}-----> Mission Completed ! <----${X}"
exec -a "[kworker/u:0]" $ROOTFS_DIR/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
