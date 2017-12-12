#!/bin/bash

set -m

# Send SIGTERM to child processes of PID 1.
function signal_handler()
{
	kill $pid
}

function mount_dev()
{
	mkdir -p /tmp
	mount -t devtmpfs none /tmp
	mkdir -p /tmp/shm
	mount --move /dev/shm /tmp/shm
	mkdir -p /tmp/mqueue
	mount --move /dev/mqueue /tmp/mqueue
	mkdir -p /tmp/pts
	mount --move /dev/pts /tmp/pts
	touch /tmp/console
	mount --move /dev/console /tmp/console
	umount /dev || true
	mount --move /tmp /dev

	# Since the devpts is mounted with -o newinstance by Docker, we need to make
	# /dev/ptmx point to its ptmx.
	# ref: https://www.kernel.org/doc/Documentation/filesystems/devpts.txt
	ln -sf /dev/pts/ptmx /dev/ptmx
	mount -t debugfs nodev /sys/kernel/debug
}

function init_systemd()
{
	GREEN='\033[0;32m'
	echo -e "${GREEN}Systemd init system enabled."
	for var in $(compgen -e); do
		printf '%q="%q"\n' "$var" "${!var}"
	done > /etc/docker.env

	printf '#!/bin/bash\n exec ' > /etc/resinApp.sh
	printf '%q ' "$@" >> /etc/resinApp.sh
	chmod +x /etc/resinApp.sh

	mkdir -p /etc/systemd/system/launch.service.d
	cat <<-EOF > /etc/systemd/system/launch.service.d/override.conf
		[Service]
		WorkingDirectory=$(pwd)
	EOF

	exec env DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket /sbin/init quiet systemd.show_status=0
}

if [ ! -z "$RESIN" ] && [ ! -z "$RESIN_DEVICE_UUID" ]; then
	# run this on resin device only
	mount_dev

    # Init papirus hw
    modprobe i2c-dev
    papirus-set $DISPLAY_SIZE
fi 

echo "executing command: $@"
init_systemd "$@"
