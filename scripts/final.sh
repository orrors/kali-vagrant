#!/bin/bash
# abort this script when a command fails or a unset variable is used.
set -eu
# echo all the executed commands.
set -x

# make sure we cannot directly login as root.
usermod --lock root

# let the sudo group members use root permissions without a password.
# NB d-i automatically adds vagrant into the sudo group.
sed -i -E 's,^%sudo\s+.+,%sudo ALL=(ALL) NOPASSWD:ALL,g' /etc/sudoers

# install the wget dependency.
apt-get install -y wget

# install the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
wget -qOauthorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub
chmod 600 authorized_keys
chown -R vagrant:vagrant .
popd

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >>/etc/ssh/sshd_config

# show boot messages.
# NB the default is "quiet".
sed -i -E 's,^(GRUB_CMDLINE_LINUX_DEFAULT\s*=).*,\1"",g' /etc/default/grub

# disable the graphical terminal. its kinda slow and useless on a VM.
sed -i -E 's,#(GRUB_TERMINAL\s*=).*,\1console,g' /etc/default/grub

# apply the grub configuration.
update-grub

# reset the machine-id.
# NB systemd will re-generate it on the next boot.
# NB machine-id is indirectly used in DHCP as Option 61 (Client Identifier), which
#    the DHCP server uses to (re-)assign the same or new client IP address.
# see https://www.freedesktop.org/software/systemd/man/machine-id.html
# see https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html
echo '' >/etc/machine-id
rm -f /var/lib/dbus/machine-id

# reset the random-seed.
# NB systemd-random-seed re-generates it on every boot and shutdown.
# NB you can prove that random-seed file does not exist on the image with:
#       sudo virt-filesystems -a ~/.vagrant.d/boxes/debian-9-amd64/0/libvirt/box.img
#       sudo guestmount -a ~/.vagrant.d/boxes/debian-9-amd64/0/libvirt/box.img -m /dev/sda1 --pid-file guestmount.pid --ro /mnt
#       sudo ls -laF /mnt/var/lib/systemd
#       sudo guestunmount /mnt
#       sudo bash -c 'while kill -0 $(cat guestmount.pid) 2>/dev/null; do sleep .1; done; rm guestmount.pid' # wait for guestmount to finish.
# see https://www.freedesktop.org/software/systemd/man/systemd-random-seed.service.html
# see https://manpages.debian.org/bookworm/manpages/random.4.en.html
# see https://manpages.debian.org/bookworm/manpages/random.7.en.html
# see https://github.com/systemd/systemd/blob/master/src/random-seed/random-seed.c
# see https://github.com/torvalds/linux/blob/master/drivers/char/random.c
systemctl stop systemd-random-seed
rm -f /var/lib/systemd/random-seed

#cleanup persistent udev rules
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm /etc/udev/rules.d/70-persistent-net.rules
fi

# clean packages.
apt-get -y autoremove --purge
apt-get -y clean

#cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -vf /var/mail/*

# Clean up apt cache
find /var/cache/apt/archives -type f -exec rm -vf \{\} \;

# Clean up ntp
rm -vf /var/lib/ntp/ntp.drift
rm -vf /var/lib/ntp/ntp.conf.dhcp

# echo "Clean up dhcp leases..."
rm -vf /var/lib/dhcp/*.leases*
rm -vf /var/lib/dhcp3/*.leases*

# echo "Clean up udev rules..."
rm -vf /etc/udev/rules.d/70-persistent-cd.rules
rm -vf /etc/udev/rules.d/70-persistent-net.rules

# echo "Clean up urandom seed..."
rm -vf /var/lib/urandom/random-seed

# echo "Clean up backups..."
rm -vrf /var/backups/*;
rm -vf /etc/shadow- /etc/passwd- /etc/group- /etc/gshadow- /etc/subgid- /etc/subuid-

#flush the logs
logrotate -f /etc/logrotate.conf

# echo "Cleaning up /var/log..."
find /var/log -type f -name "*.gz" -exec rm -vf \{\} \;
find /var/log -type f -name "*.1" -exec rm -vf \{\} \;
find /var/log -type f -exec truncate -s0 \{\} \;
#clear audit logs
[ -f /var/log/audit/audit.log ] && cat /dev/null > /var/log/audit/audit.log
[ -f /var/log/wtmp ] && cat /dev/null > /var/log/wtmp
[ -f /var/log/lastlog ] && cat /dev/null > /var/log/lastlog

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
root_dev="$(findmnt -no SOURCE /)"
if [ "$(lsblk -no DISC-GRAN $root_dev | awk '{print $1}')" != '0B' ]; then
    while true; do
        output="$(fstrim -v /)"
        cat <<<"$output"
        sync && sync && sync && blockdev --flushbufs $root_dev && sleep 15
        if [ "$output" == '/: 0 B (0 bytes) trimmed' ]; then
            break
        fi
    done
else
    dd if=/dev/zero of=/EMPTY bs=1M || true; rm -f /EMPTY
fi

# echo "Clearing bash history..."
cat /dev/null > /root/.bash_history
history -c
