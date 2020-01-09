<%page args="root_password='password',time_zone='US/Eastern',locale='en_US',xkb_keymap='us',clock_utc='true',user_fullname='Debian User',user_name='debian',user_password='password',dns='1.0.0.1,1.1.1.1'"/>
#### Locale
d-i keyboard-configuration/xkb-keymap select ${xkb_keymap}
d-i debian-installer/locale string ${locale}
d-i clock-setup/utc boolean ${clock_utc}
d-i time/zone string ${time_zone}

#### Initial root password is 'password'
d-i passwd/root-password password ${root_password}
d-i passwd/root-password-again password ${root_password}

#### Initial user account: 'debian' password: 'password'
d-i passwd/user-fullname string ${user_fullname}
d-i passwd/username string ${user_name}
d-i passwd/user-password password ${user_password}
d-i passwd/user-password-again password ${user_password}

#### Network
d-i netcfg/choose_interface select ${interface}
d-i hw-detect/load_firmware boolean ${load_firmware}
d-i netcfg/hostname string ${hostname}
d-i netcfg/get_hostname string ${hostname}
d-i netcfg/get_domain string ${dhcp['domain']}

#### APT
d-i mirror/country string manual
d-i mirror/http/hostname string ${debian_mirror['hostname']}
d-i mirror/http/directory string ${debian_mirror['path']}
d-i mirror/http/port string ${debian_mirror['port']}
d-i mirror/http/proxy string

#### Partitioning
d-i partman-auto/disk string ${root_storage}
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-auto-lvm/guided_size string max
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

#### Packages
popularity-contest popularity-contest/participate boolean false
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string build-essential

#### UEFI specific
d-i partman-efi/non_efi_system true
d-i partman-basicfilesystems/choose_label string gpt
d-i partman-basicfilesystems/default_label string gpt
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
d-i partman/choose_label string gpt
d-i partman/default_label string gpt

#### Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev  string /dev/sda
d-i finish-install/reboot_in_progress note

#### Run custom handler at the end:
d-i preseed/late_command string chroot /target sh -c "/usr/bin/apt-get install -y atftp && /usr/bin/atftp -g -r preseed/${mac}_postinstall.sh -l /tmp/postinstall.sh ${public_ip} 69 && /usr/bin/bash -x /tmp/postinstall.sh && /usr/bin/apt-get purge -y atftp"
