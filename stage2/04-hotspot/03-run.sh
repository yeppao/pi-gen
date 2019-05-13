#!/bin/bash -e

# DHCP & DNS
install -v -m 755 files/dhcpcd.conf	"${ROOTFS_DIR}/etc/"
# mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
install -v -m 755 files/dnsmasq.conf "${ROOTFS_DIR}/etc/"

# IPTables
install -v -m 755 files/iptables-save "${ROOTFS_DIR}/etc/"

# Network
install -v -m 755 files/network/interfaces "${ROOTFS_DIR}/etc/network/"

# Dashboard
install -v -m 644 files/systemd/system/dashboard.service "${ROOTFS_DIR}/lib/systemd/system/"

on_chroot << EOF
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# load on boot
echo '#!/bin/sh' > /etc/network/if-up.d/iptables
echo "echo 'RUNNING iptables restore now'" >> /etc/network/if-up.d/iptables
echo "iptables-restore < /etc/iptables-save" >> /etc/network/if-up.d/iptables
echo "exit 0;" >> /etc/network/if-up.d/iptables

curl -sSL https://get.docker.com | sh
usermod -aG docker nadia
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install -y nodejs
npm install npm@latest -g
mkdir -p /home/nadia/Projects/ && cd /home/nadia/Projects/
git clone https://github.com/yeppao/rpi-dashboard.git && cd rpi-dashboard
npm install

systemctl daemon-reload
systemctl enable dashboard.service
EOF