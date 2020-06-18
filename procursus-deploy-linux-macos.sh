#!/bin/bash
if [ "$(uname)" = "Darwin" ]; then
	if [ "$(uname -p)" = "arm" ] || [ "$(uname -p)" = "arm64" ]; then
		echo "It's recommended this script be ran on macOS/Linux with a clean iOS device running checkra1n attached unless migrating from older bootstrap."
		read -p "Press enter to continue"
		ARM=yes
		if [[ "${USER}" != root ]]; then
			echo "Default password is: alpine"
			su root || { echo "Must be Root, exiting"; exit 1; }
		fi
		cd /var/root || { echo "Unable to change directory, exiting"; exit 1; }
	fi
fi

echo "odysseyra1n deployment script"
echo "(C) 2020, CoolStar. All Rights Reserved"

echo ""
echo "Before you begin: This script includes experimental migration from older bootstraps to Procursus/Odyssey."
echo "If you're already jailbroken, you can run this script on the checkra1n device."
echo "If you'd rather start clean, please Reset System via the Loader app first."
read -p "Press enter to continue"

if ! which curl >> /dev/null; then
	echo "Error: curl not found"
	exit 1
fi
if [[ "${ARM}" = yes ]]; then
	if ! which zsh >> /dev/null; then
		echo "Error: zsh not found"
		exit 1
	fi
else
	if which iproxy >> /dev/null; then
		iproxy 4444 44 >> /dev/null 2>/dev/null &
	else
		echo "Error: iproxy not found"
		exit 1
	fi
	TMP="$(mktemp -d 2>/dev/null || { rm -rf odyssey-tmp; mkdir odyssey-tmp; })"
	cd "${TMP:-odyssey-tmp}" || { echo "Unable to change directory, exiting"; exit 1; }
fi

cat <<'EOF' > odyssey-device-deploy.sh
#!/bin/zsh
if [[ "${USER}" != root ]]; then
	echo "Default password is: alpine"
	su root || { echo "Must be Root, exiting"; exit 1; }
fi
cd /var/root || { echo "Unable to change directory, exiting"; exit 1; }
if [[ -f "/.bootstrapped" ]]; then
	mkdir -p /odyssey && mv migration /odyssey
	chmod 0755 /odyssey/migration
	/odyssey/migration
	rm -rf /odyssey
else
	VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
	if [[ "${VER%.*}" -ge 12 ]] && [[ "${VER%.*}" -lt 13 ]]; then
		CFVER=1500
	elif [[ "${VER%.*}" -ge 13 ]]; then
		CFVER=1600
	else
		echo "${VER} not compatible."
		exit 1
	fi
	gzip -d bootstrap_${CFVER}-ssh.tar.gz
	mount -uw -o union /dev/disk0s1s1
	rm -rf /etc/profile
	rm -rf /etc/profile.d
	rm -rf /etc/alternatives
	rm -rf /etc/apt
	rm -rf /etc/ssl
	rm -rf /etc/ssh
	rm -rf /etc/dpkg
	rm -rf /Library/dpkg
	rm -rf /var/cache
	rm -rf /var/lib
	tar --preserve-permissions -xkf bootstrap_${CFVER}-ssh.tar -C /
	/Library/dpkg/info/openssh.postinst || true
	launchctl load -w /Library/LaunchDaemons/com.openssh.sshd.plist || true
	SNAPSHOT=$(snappy -s | cut -d " " -f 3 | tr -d '\n')
	snappy -f / -r $SNAPSHOT -t orig-fs
fi
/usr/libexec/firmware
mkdir -p /etc/apt/sources.list.d/
echo "Types: deb" > /etc/apt/sources.list.d/odyssey.sources
echo "URIs: https://repo.theodyssey.dev/" >> /etc/apt/sources.list.d/odyssey.sources
echo "Suites: ./" >> /etc/apt/sources.list.d/odyssey.sources
echo "Components: " >> /etc/apt/sources.list.d/odyssey.sources
echo "" >> /etc/apt/sources.list.d/odyssey.sources
mkdir -p /etc/apt/preferences.d/
echo "Package: *" > /etc/apt/preferences.d/odyssey
echo "Pin: release n=odyssey-ios" >> /etc/apt/preferences.d/odyssey
echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/odyssey
echo "" >> /etc/apt/preferences.d/odyssey
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.coolstar.sileo_1.8.1_iphoneos-arm.deb
uicache -p /Applications/Sileo.app
echo -n "" > /var/lib/dpkg/available
/Library/dpkg/info/profile.d.postinst
touch /.mount_rw
touch /.installed_odyssey
rm bootstrap*.tar*
rm org.coolstar.sileo_1.8.1_iphoneos-arm.deb
rm odyssey-device-deploy.sh
rm migration 2>/dev/null
apt-get update
apt-get install org.coolstar.libhooker || echo "Unable to install libhooker. Open Sileo and do so manually"
EOF

echo "Downloading Resources..."
curl -L -O https://github.com/coolstar/odyssey-bootstrap/raw/master/bootstrap_1500-ssh.tar.gz -O https://github.com/coolstar/odyssey-bootstrap/raw/master/bootstrap_1600-ssh.tar.gz -O https://github.com/coolstar/odyssey-bootstrap/raw/master/migration -O https://github.com/coolstar/odyssey-bootstrap/raw/master/org.coolstar.sileo_1.8.1_iphoneos-arm.deb
clear
if [[ ! "${ARM}" = yes ]]; then
	echo "Copying Files to your device"
	echo "Default password is: alpine"
	scp -P4444 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap_1500-ssh.tar.gz bootstrap_1600-ssh.tar.gz migration org.coolstar.sileo_1.8.1_iphoneos-arm.deb odyssey-device-deploy.sh root@127.0.0.1:/var/root/
	clear
fi
echo "Installing Procursus bootstrap and Sileo on your device"
if [[ "${ARM}" = yes ]]; then
	zsh ./odyssey-device-deploy.sh
else
	echo "Default password is: alpine"
	ssh -p4444 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "zsh /var/root/odyssey-device-deploy.sh"
	echo "All Done!"
	killall iproxy
fi
