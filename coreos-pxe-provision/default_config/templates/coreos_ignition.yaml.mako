<% import uuid %>
variant: fcos
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
% for key in ssh_keys:
        - ${key}
% endfor
systemd:
  units:
    - name: docker.service
      enabled: false
      contents: |
        [Unit]
        Description=disable docker

        [Service]

        [Install]
        WantedBy=multi-user.target

    - name: hello.service
      enabled: true
      contents: |
        [Unit]
        Description=hashicorp/http-echo
        After=network-online.target

        [Service]
        TimeoutStartSec=0
        ExecStartPre=-/bin/podman kill echo-http-server
        ExecStartPre=-/bin/podman rm echo-http-server
        ExecStartPre=/bin/podman pull hashicorp/http-echo
        ExecStart=/bin/podman run --rm hashicorp/http-echo -text="hello" -listen=:8080

        [Install]
        WantedBy=multi-user.target
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
