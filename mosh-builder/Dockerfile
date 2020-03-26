FROM fedora:31 AS mosh-builder

RUN dnf update -y && \
    dnf install -y @development-tools gcc-g++ protobuf-devel \
                ncurses-devel openssl-devel automake autoconf
RUN curl -L https://raw.githubusercontent.com/mig1984/bashible/0.3/bashible -o /usr/local/bin/bashible && \
    curl -L https://raw.githubusercontent.com/mig1984/bashible/0.3/bashible.edit -o /usr/local/bin/bashible.edit && \
    chmod 755 /usr/local/bin/bashible && \
    chmod 755 /usr/local/bin/bashible.edit

CMD ["/usr/local/bin/bashible", "/host/mosh-builder.ble"]

