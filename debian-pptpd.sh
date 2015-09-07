#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

clear
CUR_DIR=$(pwd)

if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!"
    exit 1
fi

echo "#############################################################"
echo "# PPTP VPN Auto Install"
echo "# Env: Debian/Ubuntu"
echo "# Created by WangYan on 2011.05.20"
echo "# Author Url: http://wangyan.org"
echo "# Version: 1.0"
echo "#############################################################"
echo ""

apt-get -y update
apt-get -y install pptpd

cat >>/etc/pptpd.conf<<EOF
localip 10.10.10.1
remoteip 10.10.10.2-254
EOF

cp /etc/ppp/pptpd-options /etc/ppp/pptpd-options.old

cat >/etc/ppp/pptpd-options<<EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
debug
dump
lock
nobsdcomp
novj
novjccomp
logfile /var/log/pptpd.log
EOF

cat >>/etc/ppp/chap-secrets<<EOF
test * test *
EOF

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

iptables-save > /etc/iptables.down.rules

iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j MASQUERADE
#iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1300

iptables-save > /etc/iptables.up.rules

cat >>/etc/ppp/pptpd-options<<EOF
pre-up iptables-restore < /etc/iptables.up.rules
post-down iptables-restore < /etc/iptables.down.rules
EOF

/etc/init.d/pptpd restart
