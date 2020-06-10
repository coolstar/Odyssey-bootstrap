#!/bin/zsh
cd /var/root
if [[ -f "/.bootstrapped" ]]; then
echo "Devices already bootstrapped with checkra1n are not currently supported."
exit 1
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
mount -uw -o union /dev/disk0s1s1
/binpack/usr/local/bin/wget https://github.com/M1staAwesome/Odyssey-bootstrap/raw/master/bootstrap_$CFVER-ssh.tar.gz https://github.com/M1staAwesome/Odyssey-bootstrap/raw/master/org.coolstar.sileo_1.8.1_iphoneos-arm.deb
tar --preserve-permissions -xkf bootstrap_${CFVER}-ssh.tar.gz -C /
/Library/dpkg/info/openssh.postinst || true
launchctl load -w /Library/LaunchDaemons/com.openssh.sshd.plist || true
SNAPSHOT=$(snappy -s | cut -d ' ' -f 3 | tr -d '\n')
snappy -f / -r $SNAPSHOT -t orig-fs
fi
/usr/libexec/firmware
mkdir -p /etc/apt/sources.list.d/
echo "Types: deb" > /etc/apt/sources.list.d/odyssey.sources
echo "URIs: https://repo.theodyssey.dev/" >> /etc/apt/sources.list.d/odyssey.sources
echo "Suites: ./" >> /etc/apt/sources.list.d/odyssey.sources
echo "Components: " >> /etc/apt/sources.list.d/odyssey.sources
echo "" >> /etc/apt/sources.list.d/odyssey.sources
mkdir -p /etc/apt/preferenced.d/
echo "Package: *" > /etc/apt/preferenced.d/odyssey
echo "Pin: release n=odyssey-ios" >> /etc/apt/preferenced.d/odyssey
echo "Pin-Priority: 1001" >> /etc/apt/preferenced.d/odyssey
echo "" >> /etc/apt/preferenced.d/odyssey
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.coolstar.sileo_1.8.1_iphoneos-arm.deb
uicache -p /Applications/Sileo.app
echo -n "" > /var/lib/dpkg/available
/Library/dpkg/info/profile.d.postinst
touch /.mount_rw
touch /.installed_odyssey
rm bootstrap*.tar*
rm org.coolstar.sileo_1.8.1_iphoneos-arm.deb
rm odyssey-device-deploy.sh
