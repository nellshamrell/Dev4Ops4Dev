#!/bin/bash


BOX_URL="https://www.dropbox.com/s/4rquhowc55sj1nx/d4-workshop-0.5.0.box?dl=0"

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
