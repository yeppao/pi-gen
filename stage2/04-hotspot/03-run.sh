#!/bin/bash -e

# DHCP & DNS
install -v -m 755 files/dhcpcd.conf	"${ROOTFS_DIR}/etc/"
# mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
install -v -m 755 files/dnsmasq.conf "${ROOTFS_DIR}/etc/"

# HostAPD
install -v -m 755 files/hostapd/hostapd.conf "${ROOTFS_DIR}/etc/hostapd/"
install -v -m 755 files/default/hostapd "${ROOTFS_DIR}/etc/default/"

# IPTables
install -v -m 755 files/iptables-save "${ROOTFS_DIR}/etc/"

# Network
install -v -m 755 files/network/interfaces "${ROOTFS_DIR}/etc/network/"

on_chroot << EOF
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# load on boot
echo '#!/bin/sh' > /etc/network/if-up.d/iptables
echo "echo 'RUNNING iptables restore now'" >> /etc/network/if-up.d/iptables
echo "iptables-restore < /etc/iptables-save" >> /etc/network/if-up.d/iptables
echo "exit 0;" >> /etc/network/if-up.d/iptables

systemctl enable dhcpcd
systemctl enable hostapd

curl -sSL https://get.docker.com | sh
usermod -aG docker nadia

curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -  # Install NodeJS v10
sudo apt-get install -y nodejs
npm install npm@latest -g
mkdir -p /home/nadia/Projects/
cd /home/nadia/Projects/
git clone https://github.com/yeppao/rpi-dashboard.git
cd rpi-dashboard
npm install
EOF