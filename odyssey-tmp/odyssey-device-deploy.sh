#!/bin/zsh
cd /var/root
if [[ -f "/.bootstrapped" ]]; then
mkdir -p /odyssey && mv migration /odyssey
/odyssey/migration
rm -rf /odyssey/migration
else
VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
if [[ "${VER}" -ge 12 ]] && [[ "${VER}" -lt 13 ]]; then
CFVER=1500
elif [[ "${VER}" -ge 13 ]]; then
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
SNAPSHOT=$(snappy -s | cut -d ' ' -f 3 | tr -d '\n')
snappy -f / -r $SNAPSHOT -t orig-fs
fi
/usr/libexec/firmware
mkdir -p /etc/apt/sources.list.d/
echo "Types: deb" > /etc/apt/sources.list.d/odyssey.sources
echo "URIs: https://repo.odyssey.dev/" >> /etc/apt/sources.list.d/odyssey.sources
echo "Suites: ./" >> /etc/apt/sources.list.d/odyssey.sources
echo "Components: " >> /etc/apt/sources.list.d/odyssey.sources
echo "" >> /etc/apt/sources.list.d/odyssey.sources
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.coolstar.sileo_1.7.6_iphoneos-arm.deb
uicache -p /Applications/Sileo.app
echo -n "" > /var/lib/dpkg/available
/Library/dpkg/info/profile.d.postinst
touch /.mount_rw
touch /.installed_odyssey
rm bootstrap*.tar*
rm migration
rm org.coolstar.sileo_1.7.6_iphoneos-arm.deb
rm odyssey-device-deploy.sh
