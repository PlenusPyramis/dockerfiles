#!/bin/sh
KEY_DIR=/etc/ssh/keys
mkdir -p $KEY_DIR
if [ ! -f $KEY_DIR/ssh_host_rsa_key ] && [ ! -f $KEY_DIR/ssh_host_ecdsa_key ] && [ ! -f $KEY_DIR/ssh_host_ed25519_key ]; then
    ls -la $KEY_DIR
    echo "No host keys found, generating fresh ones..."
    ssh-keygen -P "" -t rsa -f $KEY_DIR/ssh_host_rsa_key
    ssh-keygen -P "" -t ecdsa -f $KEY_DIR/ssh_host_ecdsa_key
    ssh-keygen -P "" -t ed25519 -f $KEY_DIR/ssh_host_ed25519_key
    echo "----"
fi
/usr/sbin/sshd -D
