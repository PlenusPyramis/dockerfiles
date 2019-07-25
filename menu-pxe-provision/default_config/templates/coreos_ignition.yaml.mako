variant: fcos
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
% for key in ssh_keys:
        - ${key}
% endfor
