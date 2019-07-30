[Unit]
Description=hashicorp/http-echo
After=network-online.target

[Service]
TimeoutStartSec=0
ExecStartPre=-/bin/podman kill echo-http-server
ExecStartPre=-/bin/podman rm echo-http-server
ExecStartPre=/bin/podman pull hashicorp/http-echo
ExecStart=/bin/podman run --rm -p 8080:8080 hashicorp/http-echo -text="${text}" -listen=:8080

[Install]
WantedBy=multi-user.target
