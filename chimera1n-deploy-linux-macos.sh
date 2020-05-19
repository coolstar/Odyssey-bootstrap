#!/bin/bash
if [ $(uname) = "Darwin" ]; then
	if [ $(uname -p) = "arm" ] || [ $(uname -p) = "arm64" ]; then
		echo "This script needs to be run on macOS/Linux with a clean iOS device running checkra1n attached."
		exit 1
	fi
fi

echo "chimera1n deployment script"
echo "(C) 2020, CoolStar. All Rights Reserved"

echo ""
echo "Before you begin: Please make sure your checkra1n device has been rootfs restored and that Loader has not been run on it"
read -p "Press enter to continue"

if ! which curl >> /dev/null; then
	echo "Error: curl not found"
	exit 1
fi
if which iproxy >> /dev/null; then
	iproxy 4444 44 >> /dev/null 2>/dev/null &
else
	echo "Error: iproxy not found"
	exit 1
fi
rm -rf chimera-tmp
mkdir chimera-tmp
cd chimera-tmp

echo '#!/bin/bash' > chimera-device-deploy.sh
echo 'cd /var/root' >> chimera-device-deploy.sh
echo 'gzip -d bootstrap.tar.gz' >> chimera-device-deploy.sh
echo 'gzip -d launchctl.gz' >> chimera-device-deploy.sh
echo 'mount -uw -o union /dev/disk0s1s1' >> chimera-device-deploy.sh
echo 'cp launchctl /bin/launchctl' >> chimera-device-deploy.sh
echo 'chmod +x /bin/launchctl' >> chimera-device-deploy.sh
echo 'rm -rf /etc/profile' >> chimera-device-deploy.sh
echo 'rm -rf /etc/profile.d' >> chimera-device-deploy.sh
echo 'rm -rf /etc/alternatives' >> chimera-device-deploy.sh
echo 'rm -rf /etc/apt' >> chimera-device-deploy.sh
echo 'rm -rf /etc/ssl' >> chimera-device-deploy.sh
echo 'rm -rf /etc/ssh' >> chimera-device-deploy.sh
echo 'rm -rf /etc/dpkg' >> chimera-device-deploy.sh
echo 'rm -rf /Library/dpkg' >> chimera-device-deploy.sh
echo 'rm -rf /var/cache' >> chimera-device-deploy.sh
echo 'rm -rf /var/lib' >> chimera-device-deploy.sh
echo 'tar --preserve-permissions -xkf bootstrap.tar -C /' >> chimera-device-deploy.sh
echo '/usr/libexec/cydia/firmware.sh' >> chimera-device-deploy.sh
echo 'mkdir -p /etc/apt/sources.list.d/' >> chimera-device-deploy.sh
echo 'echo "Types: deb" > /etc/apt/sources.list.d/chimera.sources' >> chimera-device-deploy.sh
echo 'echo "URIs: https://repo.chimera.sh/" >> /etc/apt/sources.list.d/chimera.sources' >> chimera-device-deploy.sh
echo 'echo "Suites: ./" >> /etc/apt/sources.list.d/chimera.sources' >> chimera-device-deploy.sh
echo 'echo "Components: " >> /etc/apt/sources.list.d/chimera.sources' >> chimera-device-deploy.sh
echo 'echo "" >> /etc/apt/sources.list.d/chimera.sources' >> chimera-device-deploy.sh
echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i cydia_2.3_iphoneos-arm.deb org.coolstar.sileo_1.7.4_iphoneos-arm.deb' >> chimera-device-deploy.sh
echo 'echo -n "" > /var/lib/dpkg/available' >> chimera-device-deploy.sh
echo '/Library/dpkg/info/openssh.postinst' >> chimera-device-deploy.sh
echo '/Library/dpkg/info/profile.d.postinst' >> chimera-device-deploy.sh
echo 'launchctl load -w /Library/LaunchDaemons/com.openssh.sshd.plist' >> chimera-device-deploy.sh
echo 'uicache -p /Applications/Sileo.app' >> chimera-device-deploy.sh
printf %s 'SNAPSHOT=$(snappy -s | ' >> chimera-device-deploy.sh
printf %s "cut -d ' ' -f 3 | tr -d '\n')" >> chimera-device-deploy.sh
echo '' >> chimera-device-deploy.sh
echo 'snappy -f / -r $SNAPSHOT -t orig-fs' >> chimera-device-deploy.sh
echo 'touch /.mount_rw' >> chimera-device-deploy.sh
echo 'touch /.bootstrapped' >> chimera-device-deploy.sh
echo 'rm bootstrap.tar' >> chimera-device-deploy.sh
echo 'rm cydia_2.3_iphoneos-arm.deb' >> chimera-device-deploy.sh
echo 'rm launchctl' >> chimera-device-deploy.sh
echo 'rm org.coolstar.sileo_1.7.4_iphoneos-arm.deb' >> chimera-device-deploy.sh
echo 'rm chimera-device-deploy.sh' >> chimera-device-deploy.sh

echo "Downloading Resources..."
curl -L -O https://github.com/coolstar/Chimera-bootstrap/raw/master/bootstrap.tar.gz -O https://github.com/coolstar/Chimera-bootstrap/raw/master/launchctl.gz -O https://github.com/coolstar/Chimera-bootstrap/raw/master/cydia_2.3_iphoneos-arm.deb -O https://github.com/coolstar/Chimera-bootstrap/raw/master/org.coolstar.sileo_1.7.4_iphoneos-arm.deb
clear
echo "Copying Files to your device"
echo "Default password is: alpine"
scp -P4444 "StrictHostKeyChecking no UserKnownHostsFile=/dev/null" bootstrap.tar.gz launchctl.gz cydia_2.3_iphoneos-arm.deb org.coolstar.sileo_1.7.4_iphoneos-arm.deb chimera-device-deploy.sh root@127.0.0.1:/var/root/
clear
echo "Installing Chimera bootstrap and Sileo on your device"
echo "Default password is: alpine"
ssh -p4444 "StrictHostKeyChecking no UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/chimera-device-deploy.sh"
clear
echo "All Done!"
killall iproxy
