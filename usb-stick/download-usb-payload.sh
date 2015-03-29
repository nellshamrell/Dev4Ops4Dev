#!/bin/bash 

IMAGE_VERSION="0.1"
IMAGE_PATH=~/Dev4Ops4Dev-USB-Image-${IMAGE_VERSION}.dmg
IMAGE_MNT=~/Dev4Ops4Dev-USB
IMAGE_SIZE=2048

echo "Creating Disk Image"
hdiutil create -megabytes $IMAGE_SIZE -fs MS-DOS -volname Dev4Ops4Dev -o $IMAGE_PATH
if [[ $? -gt 0 ]]; then
  echo "ERROR: Unable to create empty image! "
  exit 1
fi

echo "Mounting Disk Image (${IMAGE_MNT})"
hdiutil attach -mountpoint $IMAGE_MNT $IMAGE_PATH
if [[ $? -gt 0 ]]; then
  echo "ERROR: Unable to mount image!"
  exit 1
fi

cd ${IMAGE_MNT}

echo "Fetching Contents"

# 0.4.0
BOX_URL="https://www.dropbox.com/s/1o98s81qqz1mzkw/d4-workshop-0.4.0.box?dl=0"

# TODO: windows aux tools
# http://the.earth.li/~sgtatham/putty/latest/x86/putty-0.64-installer.exe

if true; then
    echo "=================================="
    echo 'Fetching VirtualBox'
    mkdir -p VirtualBox
    cd VirtualBox
    URLS="
http://download.virtualbox.org/virtualbox/4.3.26/VirtualBox-4.3.26-98988-Win.exe
http://download.virtualbox.org/virtualbox/4.3.26/VirtualBox-4.3.26-98988-OSX.dmg
http://download.virtualbox.org/virtualbox/4.3.26/virtualbox-4.3_4.3.26-98988~Ubuntu~raring_amd64.deb
http://download.virtualbox.org/virtualbox/4.3.26/VirtualBox-4.3-4.3.26_98988_el6-1.x86_64.rpm
http://download.virtualbox.org/virtualbox/4.3.26/VirtualBox-4.3-4.3.26_98988_el7-1.x86_64.rpm
"
    for url in $URLS; do
        echo "--------------"
        echo -n '                      '
        echo $url | cut -c 50-
        CMD="curl"
        CMD="${CMD} -L" # Follow redirects
        CMD="${CMD} -O" # Save response body in a file named like the URL file component
        CMD="${CMD} -C -" # Continue interrupted downloads; errors on complete file, alas.
        CMD="${CMD} --retry 3" # Keep trying if interrupted
        CMD="${CMD} -Y 10240" # Abort and restart if rate falls below 10K for 30 sec
        $CMD $url
    done
    cd ..
fi

if true; then
    echo
    echo "=================================="
    echo 'Fetching Vagrant'
    mkdir -p Vagrant
    cd Vagrant
    URLS="
https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.dmg
https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.msi
https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.rpm
"
    for url in $URLS; do
        echo "--------------"
        echo -n '                      '
        echo $url | cut -c 42-
        CMD="curl"
        CMD="${CMD} -L" # Follow redirects
        CMD="${CMD} -O" # Save response body in a file named like the URL file component
        CMD="${CMD} -C -" # Continue interrupted downloads; errors on complete file, alas.
        CMD="${CMD} --retry 3" # Keep trying if interrupted
        CMD="${CMD} -Y 10240" # Abort and restart if rate falls below 10K for 30 sec
        $CMD $url
    done
    cd ..
fi

if true; then
    echo
    echo "=================================="
    echo 'Fetching the Workshop Vagrant Box'
    CMD="curl"
    CMD="${CMD} -L" # Follow redirects
    CMD="${CMD} -o workshop.box" # Save in filename of our choosing
    CMD="${CMD} -C -" # Continue interrupted downloads; errors on complete file, alas.
    CMD="${CMD} --retry 3" # Keep trying if interrupted
    CMD="${CMD} -Y 10240" # Abort and restart if rate falls below 10K for 30 sec
    $CMD $BOX_URL
fi


if which tree 2>/dev/null >/dev/null; then
    tree -s
fi

du -h -s

echo "Closing up USB Image"
hdiutil unmount ${IMAGE_MNT}

echo "Done!  Image ${IMAGE_PATH} ready for use!"
echo ""
echo "1) Insert a USB Key, find the device number using: diskutil list"
echo "2) Unmount any volumes on device using: diskutil unmountDisk /dev/diskX"
echo "3) To create key, simply: dd if=${IMAGE_PATH} of=/dev/rdiskX bs=1m"
