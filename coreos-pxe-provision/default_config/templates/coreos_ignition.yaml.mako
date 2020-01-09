<% import uuid, crypt %>
variant: fcos
version: 1.0.0
passwd:
  users:
    - name: ${username}
% if password != None:
      password_hash: ${crypt.crypt(password)}
% endif
      ssh_authorized_keys:
% for key in ssh_keys:
        - ${key}
% endfor
systemd:
  units:
    - name: post-install.service
      enabled: true
      contents: |
        [Unit]
        Description=self-destructing post-install tasks to happen on second boot
        Type=idle

        [Service]
        Type=oneshot
        ExecStart=/bin/sh -c "rm -f /etc/systemd/system/post-install.service && hostnamectl set-hostname ${hostname} && /sbin/reboot"
        StandardOutput=journal

        [Install]
        WantedBy=multi-user.target

% for unit in units:
    - name: ${unit['name']}
      enabled: ${unit['enabled']}
      contents: "${unit['contents']}"
% endfor

storage:
  files:
    - path: /etc/NetworkManager/system-connections/${interface}.nmconnection
      contents:
        inline: |
         [connection]
         id=${interface}
         uuid=${uuid.uuid4()}
         type=802-3-ethernet
         autoconnect=true

         [ipv4]
         method=manual
% for ip in dns: 
         dns=${ip}
% endfor
         addresses=${ip_address}/${cidr}
         gateway=${dhcp['gateway']}

         [802-3-ethernet]
         mac-address=${mac.replace('-',':')}
      mode: 0600
