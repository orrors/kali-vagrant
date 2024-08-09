#!/bin/bash
set -exu

# This is a clenup script to remove all possible unneded files
#  and zero out the empty space so the generated machine image
#  can be as small as possible


# show boot messages.
#    the default is "quiet".
sed -i -E 's,^(GRUB_CMDLINE_LINUX_DEFAULT\s*=).*,\1"",g' /etc/default/grub
# disable the graphical terminal. its kinda slow and useless on a VM.
sed -i -E 's,#(GRUB_TERMINAL\s*=).*,\1console,g' /etc/default/grub
# Boot more quickly
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub

# apply the grub configuration.
update-grub

# reset the machine-id.
#    systemd will re-generate it on the next boot.
#    machine-id is indirectly used in DHCP as Option 61 (Client Identifier), which
#    the DHCP server uses to (re-)assign the same or new client IP address.
echo '' >/etc/machine-id
rm -f /var/lib/dbus/machine-id

# reset the random-seed.
#    systemd-random-seed re-generates it on every boot and shutdown.
systemctl stop systemd-random-seed
rm -f /var/lib/systemd/random-seed

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
#    prefer discard/trim (safer; faster) over creating a big zero filled file
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
