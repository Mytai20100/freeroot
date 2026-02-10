#!/bin/sh
export LC_ALL=C
export LANG=C  
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=10
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_ALT=amd64 ;;
    aarch64) ARCH_ALT=arm64 ;;
    *) printf "Unsupported CPU: ${ARCH}\n"; exit 1 ;;
esac
df() {
    url="$1"; output="$2"; retries=0
    while [ $retries -lt $max_retries ]; do
        if command -v wget >/dev/null 2>&1; then
            wget -q --tries=3 --timeout=$timeout --no-hsts -O "$output" "$url" 2>/dev/null
        elif command -v curl >/dev/null 2>&1; then
            curl -f -s -L --max-time $timeout --retry 3 -o "$output" "$url" 2>/dev/null
        else
            printf "Error: Neither wget nor curl found\n"; return 1
        fi
        [ -s "$output" ] && [ $(stat -c%s "$output" 2>/dev/null || stat -f%z "$output" 2>/dev/null) -gt 1024 ] && return 0
        rm -f "$output"; retries=$((retries + 1)); sleep 1
    done
    return 1
}
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "###################################################################"
    echo "#              Proot INSTALLER - Copyright (C) 2024-2026          #"
    echo "###################################################################"
    df "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz" "/tmp/rootfs.tar.gz"
    [ ! -s /tmp/rootfs.tar.gz ] && echo "Error: Failed to download rootfs" && exit 1
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR 2>/dev/null
    mkdir -p $ROOTFS_DIR/usr/local/bin
    df "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}" "$ROOTFS_DIR/usr/local/bin/proot"
    [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ] && echo "Error: Failed to download proot" && exit 1
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > ${ROOTFS_DIR}/etc/resolv.conf
    rm -rf /tmp/rootfs.tar.gz /tmp/sbin
    touch $ROOTFS_DIR/.installed
fi
echo "node" > $ROOTFS_DIR/etc/hostname
cat > $ROOTFS_DIR/etc/hosts << 'HOSTS_EOF'
127.0.0.1   localhost
127.0.1.1   node
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
HOSTS_EOF
cat > $ROOTFS_DIR/root/.bashrc << 'BASHRC_EOF'
export HOSTNAME=node
export PS1='root@node:\w\$ '
export LC_ALL=C
export LANG=C
export TMOUT=0
unset TMOUT
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
BASHRC_EOF
G="\033[0;32m"
Y="\033[0;33m"
R="\033[0;31m"
C="\033[0;36m"
W="\033[0;37m"
X="\033[0m"
OS=$(lsb_release -ds 2>/dev/null||cat /etc/os-release 2>/dev/null|grep PRETTY_NAME|cut -d'"' -f2||echo "Unknown")
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
get_disk_info() {
    command df -h / 2>/dev/null | awk 'NR==2{print $0}'
}
DISK_INFO=$(get_disk_info)
DISK=$(echo "$DISK_INFO" | awk '{print $2}')
UDISK=$(echo "$DISK_INFO" | awk '{print $3}')
DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}' | sed 's/%//')
if [ "$DISK_PERCENT" -gt 80 ] 2>/dev/null; then
    DISK_COLOR=$R
elif [ "$DISK_PERCENT" -gt 60 ] 2>/dev/null; then
    DISK_COLOR=$Y
else
    DISK_COLOR=$G
fi
IP=$(curl -s --max-time 2 ifconfig.me 2>/dev/null||curl -s --max-time 2 icanhazip.com 2>/dev/null||hostname -I 2>/dev/null|awk '{print $1}'||echo "N/A")
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
    exec -a "[kworker/u:0]" $ROOTFS_DIR/usr/local/bin/proot --rootfs="${ROOTFS_DIR}" -0 -w "/" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /init.sh
else
    exec -a "[kworker/u:0]" $ROOTFS_DIR/usr/local/bin/proot --rootfs="${ROOTFS_DIR}" -0 -w "/root" -b /dev -b /dev/pts -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/bash --rcfile /root/.bashrc -i
fi
