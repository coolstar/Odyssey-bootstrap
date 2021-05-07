#!/bin/bash
if [ $(uname) = "Darwin" ]; then
	if [ $(uname -p) = "arm" ] || [ $(uname -p) = "arm64" ]; then
		echo "It's recommended that this script be ran on macOS/Linux with a non-bootstrapped iOS device running checkra1n attached."
		read -p "Press enter to continue"
		ARM=yes
	fi
fi

CURRENTDIR=$(pwd)
ODYSSEYDIR=$(mktemp -d)

echo "Odysseyra1n Installation Script"
echo "(C) 2021, CoolStar. All Rights Reserved"
echo ""
echo "Before you begin: If you're currently jailbroken with a different bootstrap installed, you will need to Reset System via the Loader app before running this script."
read -p "Press enter to continue."
echo ""

if ! which curl > /dev/null; then
	echo "Error: cURL not found."
	exit 1
fi
if [[ "${ARM}" != yes ]]; then
	if ! which iproxy > /dev/null; then
		echo "Error: iproxy not found."
		exit 1
	fi
fi

cd $ODYSSEYDIR

echo '#!/bin/bash' > odysseyra1n-install.bash
if [[ ! "${ARM}" = yes ]]; then
	echo 'cd /var/root' >> odysseyra1n-install.bash
fi
echo 'if [[ -f "/.bootstrapped" ]]; then' >> odysseyra1n-install.bash
echo 'echo "Error: Migration from other bootstraps is no longer supported."' >> odysseyra1n-install.bash
echo 'rm bootstrap* *.deb odysseyra1n-install.bash' >> odysseyra1n-install.bash
echo 'exit 1' >> odysseyra1n-install.bash
echo 'fi' >> odysseyra1n-install.bash
echo 'if [[ -f "/.installed_odyssey" ]]; then' >> odysseyra1n-install.bash
echo 'echo "Error: Odysseyra1n is already installed."' >> odysseyra1n-install.bash
echo 'rm bootstrap* *.deb odysseyra1n-install.bash' >> odysseyra1n-install.bash
echo 'exit 1' >> odysseyra1n-install.bash
echo 'fi' >> odysseyra1n-install.bash
echo 'VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)' >> odysseyra1n-install.bash
echo 'if [[ "${VER%%.*}" -ge 12 ]] && [[ "${VER%%.*}" -lt 13 ]]; then' >> odysseyra1n-install.bash
echo 'CFVER=1500' >> odysseyra1n-install.bash
echo 'elif [[ "${VER%%.*}" -ge 13 ]]; then' >> odysseyra1n-install.bash
echo 'CFVER=1600' >> odysseyra1n-install.bash
echo 'elif [[ "${VER%%.*}" -ge 14 ]]; then' >> odysseyra1n-install.bash
echo 'CFVER=1700' >> odysseyra1n-install.bash
echo 'else' >> odysseyra1n-install.bash
echo 'echo "${VER} not compatible."' >> odysseyra1n-install.bash
echo 'exit 1' >> odysseyra1n-install.bash
echo 'fi' >> odysseyra1n-install.bash
echo 'mount -o rw,union,update /dev/disk0s1s1' >> odysseyra1n-install.bash
echo 'rm -rf /etc/{alternatives,apt,ssl,ssh,dpkg,profile{,.d}} /Library/dpkg /var/{cache,lib}' >> odysseyra1n-install.bash
echo 'gzip -d bootstrap_${CFVER}.tar.gz' >> odysseyra1n-install.bash
echo 'tar --preserve-permissions -xkf bootstrap_${CFVER}.tar -C /' >> odysseyra1n-install.bash
printf %s 'SNAPSHOT=$(snappy -s | ' >> odysseyra1n-install.bash
printf %s "cut -d ' ' -f 3 | tr -d '\n')" >> odysseyra1n-install.bash
echo '' >> odysseyra1n-install.bash
echo 'snappy -f / -r $SNAPSHOT -t orig-fs >/dev/null 2>&1' >> odysseyra1n-install.bash
echo '/prep_bootstrap.sh >/dev/null 2>&1' >> odysseyra1n-install.bash
echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games' >> odysseyra1n-install.bash
echo 'if [[ $VER = 12.1* ]] || [[ $VER = 12.0* ]]; then' >> odysseyra1n-install.bash
echo 'dpkg -i org.swift.libswift_5.0-electra2_iphoneos-arm.deb > /dev/null' >> odysseyra1n-install.bash
echo 'fi' >> odysseyra1n-install.bash
echo 'echo "(4) Installing Sileo..."'  >> odysseyra1n-install.bash
echo 'dpkg -i org.coolstar.sileo_2.0.3_iphoneos-arm.deb > /dev/null' >> odysseyra1n-install.bash
echo 'mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d' >> odysseyra1n-install.bash
echo 'echo "Types: deb" > /etc/apt/sources.list.d/odyssey.sources' >> odysseyra1n-install.bash
echo 'echo "URIs: https://repo.theodyssey.dev/" >> /etc/apt/sources.list.d/odyssey.sources' >> odysseyra1n-install.bash
echo 'echo "Suites: ./" >> /etc/apt/sources.list.d/odyssey.sources' >> odysseyra1n-install.bash
echo 'echo "Components: " >> /etc/apt/sources.list.d/odyssey.sources' >> odysseyra1n-install.bash
echo 'echo "" >> /etc/apt/sources.list.d/odyssey.sources' >> odysseyra1n-install.bash
echo 'touch /var/lib/dpkg/available' >> odysseyra1n-install.bash
echo 'touch /.mount_rw' >> odysseyra1n-install.bash
echo 'touch /.installed_odyssey' >> odysseyra1n-install.bash
echo 'rm bootstrap* *.deb odysseyra1n-install.bash' >> odysseyra1n-install.bash
echo 'echo "Done!"' >> odysseyra1n-install.bash

echo "(1) Downloading resources..."
IPROXY=$(iproxy 28605 44 >/dev/null 2>&1 & echo $!)
curl -sLOOOOO https://github.com/coolstar/Odyssey-bootstrap/raw/update/bootstrap_1500.tar.gz https://github.com/coolstar/Odyssey-bootstrap/raw/update/bootstrap_1600.tar.gz https://github.com/coolstar/Odyssey-bootstrap/raw/update/bootstrap_1700.tar.gz https://github.com/coolstar/Odyssey-bootstrap/raw/update/org.coolstar.sileo_2.0.3_iphoneos-arm.deb https://github.com/coolstar/Odyssey-bootstrap/raw/update/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
if [[ ! "${ARM}" = yes ]]; then
	echo "(2) Copying resources to your device..."
	echo "Default password is: alpine"
	scp -qP28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap_1500.tar.gz bootstrap_1600.tar.gz bootstrap_1700.tar.gz org.coolstar.sileo_2.0.3_iphoneos-arm.deb org.swift.libswift_5.0-electra2_iphoneos-arm.deb odysseyra1n-install.bash root@127.0.0.1:/var/root/
fi
echo "(3) Bootstrapping your device..."
if [[ "${ARM}" = yes ]]; then
	bash odysseyra1n-install.bash
else
	echo "Default password is: alpine"
	ssh -qp28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/odysseyra1n-install.bash"
	kill $IPROXY
	cd $CURRENTDIR
	rm -rf $ODYSSEYDIR
fi
