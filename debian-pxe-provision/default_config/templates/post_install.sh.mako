#!/bin/bash
cat <<EOF > /etc/network/interfaces
auto ${interface}
iface ${interface} inet static
    address ${ip_address}
    netmask ${netmask}
EOF

cat <<EOF > /etc/resolv.conf
% for host in dns:
nameserver ${host}
% endfor
EOF
