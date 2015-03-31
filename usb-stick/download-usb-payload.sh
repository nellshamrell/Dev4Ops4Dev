#!/bin/bash 

#===========================================================================================#
#                                 "UI"
#===========================================================================================#
DOWNLOAD_THROTTLE=500k
BOX_URL="https://www.dropbox.com/s/4rquhowc55sj1nx/d4-workshop-0.5.0.box?dl=0"
COURSE_REPO="git@github.com:nellshamrell/Dev4Ops4Dev.git"   # TODO - this is private

# Debugging controls
DO_DOWNLOADS=true
DO_COURSE=true
DO_REPORT=true

IMAGE_VERSION="0.1"
IMAGE_PATH=~/Dev4Ops4Dev-USB-Image-${IMAGE_VERSION}.dmg
IMAGE_MNT=~/Dev4Ops4Dev-USB
IMAGE_SIZE=2048

#===========================================================================================#
#                                  Preflight
#===========================================================================================#

if ! gem list -i github-markdown-preview >/dev/null; then
    echo "Whoa, tiger.  I need you to run "
    echo "    gem install github-markdown-preview"
    echo " (may need sudo, rvm, rbenv, advil)"
    exit 1
fi

#===========================================================================================#
#                                   Disk Image 
#===========================================================================================#

if [[ ! -e $IMAGE_PATH ]]; then
    echo "Creating Disk Image"
    hdiutil create -megabytes $IMAGE_SIZE -fs MS-DOS -volname Dev4Ops4Dev -o $IMAGE_PATH
    if [[ $? -gt 0 ]]; then
        echo "ERROR: Unable to create empty image! "
        exit 1
    fi
fi

echo "Mounting Disk Image (${IMAGE_MNT})"
hdiutil attach -mountpoint $IMAGE_MNT $IMAGE_PATH
if [[ $? -gt 0 ]]; then
    echo "ERROR: Unable to mount image!"
    exit 1
fi

cd ${IMAGE_MNT}

echo "Fetching Contents"


#===========================================================================================#
#                                  Downloads
#===========================================================================================#

if $DO_DOWNLOADS; then
    echo "=================================="
    echo 'Fetching Misc Tools'
    mkdir -p misc
    cd misc
    URLS="
http://the.earth.li/~sgtatham/putty/latest/x86/putty-0.64-installer.exe
"
    for url in $URLS; do
        echo "--------------"
        echo -n '                      '
        echo $url | cut -c 48-
        CMD="wget"
        CMD="${CMD} --limit-rate $DOWNLOAD_THROTTLE" # Don't kill the hotel wifi
        CMD="${CMD} -c " # Continue interrupted downloads
        CMD="${CMD} -t 3" # Keep trying if interrupted
        CMD="${CMD} -nv" # hush
        $CMD $url
    done
    cd ..
fi

if $DO_DOWNLOADS; then
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
        CMD="wget"
        CMD="${CMD} --limit-rate $DOWNLOAD_THROTTLE" # Don't kill the hotel wifi
        CMD="${CMD} -c " # Continue interrupted downloads
        CMD="${CMD} -t 3" # Keep trying if interrupted
        CMD="${CMD} -nv" # hush
        $CMD $url
    done
    cd ..
fi

if $DO_DOWNLOADS; then
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
        CMD="wget"
        CMD="${CMD} --limit-rate $DOWNLOAD_THROTTLE" # Don't kill the hotel wifi
        CMD="${CMD} -c " # Continue interrupted downloads
        CMD="${CMD} -t 3" # Keep trying if interrupted
        CMD="${CMD} -nv" # hush
        $CMD $url
    done
    cd ..
fi

if $DO_DOWNLOADS; then
    echo
    echo "=================================="
    echo 'Fetching the Workshop Vagrant Box'
    CMD="wget"
    CMD="${CMD} --limit-rate $DOWNLOAD_THROTTLE" # Don't kill the hotel wifi
    CMD="${CMD} -O workshop.box " # specify filename
    CMD="${CMD} -c " # Continue interrupted downloads
    CMD="${CMD} -t 3" # Keep trying if interrupted
    CMD="${CMD} -nv" # hush
    $CMD $url
fi

#===========================================================================================#
#                                    Materials Render to HTML
#===========================================================================================#

if $DO_COURSE; then
    echo "=================================="
    echo 'Fetching the workshop Markdown files to convert to HTML'

    mkdir -p course_html
    cd course_html
    if [[ ! -e repo/.git ]]; then
        git clone $COURSE_REPO repo
    else
        cd repo && git pull > /dev/null && cd ..
    fi

    for f in $(find repo -name '*.md'); do
        echo ".md => .html: $f"
        # Great human UI! Terrible machine API!
        github-markdown-preview $f >/dev/null 2>&1 &
        STUPID=$!
        sleep 1
        kill -INT $STUPID
    done

    for f in $(find repo -name '*.html'); do
        mv $f .
    done
    
    rm -rf repo
    cd ..
fi

#===========================================================================================#
#                                      Disk report
#===========================================================================================#

if $DO_REPORT; then
    if which tree 2>/dev/null >/dev/null; then
        tree -h
    fi

    du -h -s
fi

echo "Closing up USB Image"
hdiutil unmount ${IMAGE_MNT}

echo "Done!  Image ${IMAGE_PATH} ready for use!"
echo ""
echo "1) Insert a USB Key, find the device number using: diskutil list"
echo "2) Unmount any volumes on device using: diskutil unmountDisk /dev/diskX"
echo "3) To create key, simply: dd if=${IMAGE_PATH} of=/dev/rdiskX bs=1m"



#===========================================================================================#
#                                DO Creds reminder
#===========================================================================================#

# Use this to map the token to a list of SSH IDs
# curl -X GET https://api.digitalocean.com/v2/account/keys -H "Authorization: Bearer $DIGITALOCEAN_ACCESS_TOKEN"

echo "Be sure to also place the digitalocean-creds.txt file"
echo "token:abababa..."
echo "key_id:1234"

echo "And the SSH private key!


