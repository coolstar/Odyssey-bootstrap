#!/bin/sh
if [ "$(uname)" = "Darwin" ]; then
	if [ "$(uname -p)" = "arm" ] || [ "$(uname -p)" = "arm64" ]; then
		if [ "$(SYSTEM_VERSION_COMPAT=1 sw_vers -productName)" != "Mac OS X" ]; then
			echo "It's recommended that this script be ran on macOS/Linux with a non-bootstrapped iOS device running checkra1n attached."
			echo "Press enter to continue"
			read -r REPLY
			ARM=yes
		fi
	fi
fi

CURRENTDIR=$(pwd)
ODYSSEYDIR=$(mktemp -d)

cat << "EOF"
Odysseyra1n Installation Script
Copyright (C) 2022, CoolStar. All Rights Reserved

Before you begin:
If you're currently jailbroken with a different bootstrap
installed, you will need to Reset System via the Loader app
before running this script.

Press enter to continue.
EOF
read -r REPLY

if ! which curl > /dev/null; then
	echo "Error: cURL not found."
	exit 1
fi
if [ "${ARM}" != yes ]; then
	if ! which iproxy > /dev/null; then
		echo "Error: iproxy not found."
		exit 1
	fi
fi

cd "$ODYSSEYDIR"

echo '#!/bin/bash' > odysseyra1n-install.bash
if [ ! "${ARM}" = yes ]; then
	echo 'cd /var/root' >> odysseyra1n-install.bash
fi
cat << "EOF" >> odysseyra1n-install.bash
if [[ -f "/.bootstrapped" ]]; then
    echo "Error: Migration from other bootstraps is no longer supported."
    rm ./bootstrap* ./*.deb odysseyra1n-install.bash
    exit 1
fi
if [[ -f "/.installed_odyssey" ]]; then
        echo "Error: Odysseyra1n is already installed."
        rm ./bootstrap* ./*.deb odysseyra1n-install.bash
        exit 1
fi
VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
if [[ "${VER%%.*}" -ge 12 ]] && [[ "${VER%%.*}" -lt 13 ]]; then
    CFVER=1500
elif [[ "${VER%%.*}" -ge 13 ]] && [[ "${VER%%.*}" -lt 14 ]]; then
    CFVER=1600
elif [[ "${VER%%.*}" -ge 14 ]] && [[ "${VER%%.*}" -lt 15 ]]; then
    CFVER=1700
else
    echo "${VER} not compatible."
    exit 1
fi
mount -o rw,union,update /dev/disk0s1s1
rm -rf /etc/{alternatives,apt,ssl,ssh,dpkg,profile{,.d}} /Library/dpkg /var/{cache,lib}
gzip -d bootstrap_${CFVER}.tar.gz
tar --preserve-permissions -xkf bootstrap_${CFVER}.tar -C /
SNAPSHOT=$(snappy -s | cut -d ' ' -f 3 | tr -d '\n')

snappy -f / -r "$SNAPSHOT" -t orig-fs > /dev/null 2>&1
/prep_bootstrap.sh
/usr/libexec/firmware
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games
if [[ $VER = 12.1* ]] || [[ $VER = 12.0* ]]; then
    dpkg -i org.swift.libswift_5.0-electra2_iphoneos-arm.deb > /dev/null
fi
echo "(4) Installing Sileo and upgrading Procursus packages..."
dpkg -i org.coolstar.sileo_2.3_iphoneos-arm.deb > /dev/null
uicache -p /Applications/Sileo.app
mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d
{
    echo "Types: deb"
    echo "URIs: https://repo.theodyssey.dev/"
    echo "Suites: ./"
    echo "Components: "
    echo ""   
} > /etc/apt/sources.list.d/odyssey.sources
touch /var/lib/dpkg/available
touch /.mount_rw
touch /.installed_odyssey
apt-get update -o Acquire::AllowInsecureRepositories=true
apt-get dist-upgrade -y --allow-downgrades --allow-unauthenticated
uicache -p /var/binpack/Applications/loader.app
rm ./bootstrap* ./*.deb odysseyra1n-install.bash
echo "Done!"
EOF

echo "(1) Downloading resources..."
IPROXY=$(iproxy 28605 44 >/dev/null 2>&1 & echo $!)
curl -sLOOOOO https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1500.tar.gz \
	https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1600.tar.gz \
	https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1700.tar.gz \
	https://github.com/coolstar/Odyssey-bootstrap/raw/master/org.coolstar.sileo_2.3_iphoneos-arm.deb \
	https://github.com/coolstar/Odyssey-bootstrap/raw/master/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
if [ ! "${ARM}" = yes ]; then
	echo "(2) Copying resources to your device..."
	echo "Default password is: alpine"
	scp -qP28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap_1500.tar.gz \
		bootstrap_1600.tar.gz bootstrap_1700.tar.gz \
		org.coolstar.sileo_2.3_iphoneos-arm.deb \
		org.swift.libswift_5.0-electra2_iphoneos-arm.deb \
		odysseyra1n-install.bash \
		root@127.0.0.1:/var/root/
fi
echo "(3) Bootstrapping your device..."
if [ "${ARM}" = yes ]; then
	bash odysseyra1n-install.bash
else
	echo "Default password is: alpine"
	ssh -qp28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/odysseyra1n-install.bash"
	kill "$IPROXY"
	cd "$CURRENTDIR"
	rm -rf "$ODYSSEYDIR"
fi
