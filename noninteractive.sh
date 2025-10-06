#!/bin/sh
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_ALT=amd64 ;;
    aarch64) ARCH_ALT=arm64 ;;
    *) printf "Unsupported CPU: ${ARCH}\n"; exit 1 ;;
esac
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "###################################################################"
    echo "#              Proot INSTALLER - Copyright (C) 2024-2025          #"
    echo "###################################################################"   
    wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"  
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR 2>/dev/null
    mkdir -p $ROOTFS_DIR/usr/local/bin 
    wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
        "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"
    while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
        rm -rf $ROOTFS_DIR/usr/local/bin/proot
        wget -q --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
            "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"
        [ -s "$ROOTFS_DIR/usr/local/bin/proot" ] && chmod 755 $ROOTFS_DIR/usr/local/bin/proot && break
        sleep 1
    done
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > ${ROOTFS_DIR}/etc/resolv.conf
    rm -rf /tmp/rootfs.tar.gz /tmp/sbin
    touch $ROOTFS_DIR/.installed
fi
G="\033[0;32m"
Y="\033[0;33m"
R="\033[0;31m"
C="\033[0;36m"
W="\033[0;37m"
X="\033[0m"
OS=$(lsb_release -ds 2>/dev/null || echo "N/A")
CPU=$(lscpu | awk -F: '/Model name:/{print $2}' | sed 's/^ *//')
ARCH_D=$(uname -m)
CPU_U=$(top -bn1 | awk '/Cpu\(s\)/{print $2+$4}')
CPU_IDLE=$(echo "100 - $CPU_U" | bc -l 2>/dev/null || echo "0")
if [ $(echo "$CPU_U > 75" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
    CPU_COLOR=$R
elif [ $(echo "$CPU_U > 50" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
    CPU_COLOR=$Y
else
    CPU_COLOR=$G
fi
TRAM=$(free -h --si | awk '/^Mem:/{print $2}')
URAM=$(free -h --si | awk '/^Mem:/{print $3}')
RAM_PERCENT=$(free | awk '/^Mem:/{printf "%.1f", $3/$2 * 100}')
if [ $(echo "$RAM_PERCENT > 80" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
    RAM_COLOR=$R
elif [ $(echo "$RAM_PERCENT > 60" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
    RAM_COLOR=$Y
else
    RAM_COLOR=$G
fi
DISK=$(df -h / | awk 'NR==2{print $2}')
UDISK=$(df -h / | awk 'NR==2{print $3}')
DISK_PERCENT=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
if [ "$DISK_PERCENT" -gt 80 ] 2>/dev/null; then
    DISK_COLOR=$R
elif [ "$DISK_PERCENT" -gt 60 ] 2>/dev/null; then
    DISK_COLOR=$Y
else
    DISK_COLOR=$G
fi
IP=$(hostname -I | awk '{print $1}')
clear
echo -e "${C}OS:${X}   $OS"
echo -e "${C}CPU:${X}  $CPU [$ARCH_D]  ${CPU_COLOR}Usage: ${CPU_U}%${X}"
echo -e "${G}RAM:${X}  ${RAM_COLOR}${URAM} / ${TRAM} (${RAM_PERCENT}%)${X}"
echo -e "${Y}Disk:${X} ${DISK_COLOR}${UDISK} / ${DISK} (${DISK_PERCENT}%)${X}"
echo -e "${C}IP:${X}   $IP"
echo -e "${W}___________________________________________________${X}"
echo -e "           ${C}-----> Mission Completed ! <----${X}"
echo -e "${W}___________________________________________________${X}"
echo ""
if [ -e $ROOTFS_DIR/init.sh ]; then
    echo -e "${Y}[*] First run: Installing bash...${X}"
    exec -a "[kworker/u:0]" $ROOTFS_DIR/usr/local/bin/proot \
        --rootfs="${ROOTFS_DIR}" \
        -0 -w "/" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
        /init.sh
else
    exec -a "[kworker/u:0]" $ROOTFS_DIR/usr/local/bin/proot \
        --rootfs="${ROOTFS_DIR}" \
        -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
        ## /bin/su -
fi
