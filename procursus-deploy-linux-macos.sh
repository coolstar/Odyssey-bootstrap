#!/bin/bash
if [ $(uname) = "Darwin" ]; then
	if [ $(uname -p) = "arm" ] || [ $(uname -p) = "arm64" ]; then
		echo "It's recommended this script be ran on macOS/Linux with a clean iOS device running checkra1n attached unless migrating from older bootstrap."
		read -p "Press enter to continue"
		ARM=yes
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
fi
rm -rf odyssey-tmp
mkdir odyssey-tmp
cd odyssey-tmp

echo '#!/bin/zsh' > odyssey-device-deploy.sh
if [[ ! "${ARM}" = yes ]]; then
	echo 'cd /var/root' >> odyssey-device-deploy.sh
fi
echo 'if [[ -f "/.bootstrapped" ]]; then' >> odyssey-device-deploy.sh
echo 'mkdir -p /odyssey && mv migration /odyssey' >> odyssey-device-deploy.sh
echo 'chmod 0755 /odyssey/migration' >> odyssey-device-deploy.sh
echo '/odyssey/migration' >> odyssey-device-deploy.sh
echo 'rm -rf /odyssey' >> odyssey-device-deploy.sh
echo 'else' >> odyssey-device-deploy.sh
echo 'VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)' >> odyssey-device-deploy.sh
echo 'if [[ "${VER%.*}" -ge 12 ]] && [[ "${VER%.*}" -lt 13 ]]; then' >> odyssey-device-deploy.sh
echo 'CFVER=1500' >> odyssey-device-deploy.sh
echo 'elif [[ "${VER%.*}" -ge 13 ]]; then' >> odyssey-device-deploy.sh
echo 'CFVER=1600' >> odyssey-device-deploy.sh
echo 'elif [[ "${VER%.*}" -ge 14 ]]; then' >> odyssey-device-deploy.sh
echo 'CFVER=1700' >> odyssey-device-deploy.sh
echo 'else' >> odyssey-device-deploy.sh
echo 'echo "${VER} not compatible."' >> odyssey-device-deploy.sh
echo 'exit 1' >> odyssey-device-deploy.sh
echo 'fi' >> odyssey-device-deploy.sh
echo 'gzip -d bootstrap_${CFVER}.tar.gz' >> odyssey-device-deploy.sh
echo 'mount -uw -o union /dev/disk0s1s1' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/profile' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/profile.d' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/alternatives' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/apt' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/ssl' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/ssh' >> odyssey-device-deploy.sh
echo 'rm -rf /etc/dpkg' >> odyssey-device-deploy.sh
echo 'rm -rf /Library/dpkg' >> odyssey-device-deploy.sh
echo 'rm -rf /var/cache' >> odyssey-device-deploy.sh
echo 'rm -rf /var/lib' >> odyssey-device-deploy.sh
echo 'tar --preserve-permissions -xkf bootstrap_${CFVER}.tar -C /' >> odyssey-device-deploy.sh
printf %s 'SNAPSHOT=$(snappy -s | ' >> odyssey-device-deploy.sh
printf %s "cut -d ' ' -f 3 | tr -d '\n')" >> odyssey-device-deploy.sh
echo '' >> odyssey-device-deploy.sh
echo 'snappy -f / -r $SNAPSHOT -t orig-fs' >> odyssey-device-deploy.sh
echo 'fi' >> odyssey-device-deploy.sh
echo '/usr/libexec/firmware' >> odyssey-device-deploy.sh
echo 'mkdir -p /etc/apt/sources.list.d/' >> odyssey-device-deploy.sh
echo 'echo "Types: deb" > /etc/apt/sources.list.d/odyssey.sources' >> odyssey-device-deploy.sh
echo 'echo "URIs: https://repo.theodyssey.dev/" >> /etc/apt/sources.list.d/odyssey.sources' >> odyssey-device-deploy.sh
echo 'echo "Suites: ./" >> /etc/apt/sources.list.d/odyssey.sources' >> odyssey-device-deploy.sh
echo 'echo "Components: " >> /etc/apt/sources.list.d/odyssey.sources' >> odyssey-device-deploy.sh
echo 'echo "" >> /etc/apt/sources.list.d/odyssey.sources' >> odyssey-device-deploy.sh
echo 'mkdir -p /etc/apt/preferences.d/' >> odyssey-device-deploy.sh
echo 'echo "Package: *" > /etc/apt/preferences.d/odyssey' >> odyssey-device-deploy.sh
echo 'echo "Pin: release n=odyssey-ios" >> /etc/apt/preferences.d/odyssey' >> odyssey-device-deploy.sh
echo 'echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/odyssey' >> odyssey-device-deploy.sh
echo 'echo "" >> /etc/apt/preferences.d/odyssey' >> odyssey-device-deploy.sh
echo 'if [[ $VER = 12.1* ]] || [[ $VER = 12.0* ]]; then' >> odyssey-device-deploy.sh
echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.swift.libswift_5.0-electra2_iphoneos-arm.deb' >> odyssey-device-deploy.sh
echo 'fi' >> odyssey-device-deploy.sh
echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.coolstar.sileo_2.0.0b6_iphoneos-arm.deb' >> odyssey-device-deploy.sh
echo 'uicache -p /Applications/Sileo.app' >> odyssey-device-deploy.sh
echo 'echo -n "" > /var/lib/dpkg/available' >> odyssey-device-deploy.sh
echo '/Library/dpkg/info/profile.d.postinst' >> odyssey-device-deploy.sh
echo 'touch /.mount_rw' >> odyssey-device-deploy.sh
echo 'touch /.installed_odyssey' >> odyssey-device-deploy.sh
echo 'rm bootstrap*.tar*' >> odyssey-device-deploy.sh
echo 'rm migration' >> odyssey-device-deploy.sh
echo 'rm org.coolstar.sileo_2.0.0b6_iphoneos-arm.deb' >> odyssey-device-deploy.sh
echo 'rm org.swift.libswift_5.0-electra2_iphoneos-arm.deb' >> odyssey-device-deploy.sh
echo 'rm odyssey-device-deploy.sh' >> odyssey-device-deploy.sh

echo "Downloading Resources..."
curl -L -O https://github.com/coolstar/odyssey-bootstrap/raw/master/bootstrap_1500.tar.gz -O https://github.com/coolstar/odyssey-bootstrap/raw/master/bootstrap_1600.tar.gz -O https://github.com/coolstar/odyssey-bootstrap/raw/master/bootstrap_1700.tar.gz -O https://github.com/coolstar/odyssey-bootstrap/raw/master/migration -O https://github.com/coolstar/odyssey-bootstrap/raw/master/org.coolstar.sileo_2.0.0b6_iphoneos-arm.deb -O https://github.com/coolstar/odyssey-bootstrap/raw/master/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
clear
if [[ ! "${ARM}" = yes ]]; then
	echo "Copying Files to your device"
	echo "Default password is: alpine"
	scp -P4444 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap_1500.tar.gz bootstrap_1600.tar.gz bootstrap_1700.tar.gz migration org.coolstar.sileo_2.0.0b6_iphoneos-arm.deb org.swift.libswift_5.0-electra2_iphoneos-arm.deb odyssey-device-deploy.sh root@127.0.0.1:/var/root/
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
