#!/bin/bash

DOWNLOAD_THROTTLE=500k
BOX_URL="https://www.dropbox.com/s/1o98s81qqz1mzkw/d4-workshop-0.4.0.box?dl=0"

# Debugging controls
DO_DOWNLOADS=true

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


if which tree 2>/dev/null >/dev/null; then
    tree -s
fi

du -h -s


# Use this to map the token to a list of SSH IDs
# curl -X GET https://api.digitalocean.com/v2/account/keys -H "Authorization: Bearer $DIGITALOCEAN_ACCESS_TOKEN"

echo "Be sure to also place the digitalocean-creds.txt file"
echo "token:abababa..."
echo "key_id:1234"

