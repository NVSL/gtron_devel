#!/usr/bin/env bash

function check_for_package_manager() {
    if ! [ -e /usr/bin/apt-get ]; then
	request "It looks like you aren't on Ubuntu, since I can't find apt-get.  You'll need to talk to someone about what to do about that."
	exit ;
    fi

}

function install_system_packages() {
    #install system-wide packages
    banner "Installing system-wide packages (this may take a while)."

    $SUDO apt-get update | save_log update_apt_get
    #verify_success # apt-get fails for non-critical reasons (like missing third-party indexes)
    $SUDO apt-get -y install $(cat ../config/ubuntu_packages.txt) | save_log install_system_packages
    verify_success
    #sudo apt-get remove arduino #  It's the wrong version, but it gives us all the support libs (E.g., java)
}

function install_eagle() {
    # install 32-bit eagle (didn’t need any of the apt-get craziness on wiki)

    if [ -e "/opt/eagle-7.4.0/bin/eagle" ]; then
	banner "Found existing /opt/eagle-7.4.0/bin/eagle.  Skipping install." | save_log install_eagle
    else
	banner "Installing Eagle..."
	(wget -O eagle-lin32-7.4.0.run http://web.cadsoft.de/ftp/eagle/program/7.4/eagle-lin32-7.4.0.run &&
	 $SUDO bash eagle-lin32-7.4.0.run) | save_log install_eagle
	verify_success

	request "Eagle is is going to ask you to create a directory.  Say yes, then exit."
	/opt/eagle-7.4.0/bin/eagle
    fi
    mkdir -p ~/eagle
}

function install_arduino() {
    #Install latest version of arduino:
    if [ -e "/usr/local/bin/arduino" ]; then
	banner "Found existing /usr/local/bin/arduino.  Skipping install." | save_log -a install_GAE
    else
	banner "Installing latest version of Arduino..."
	(wget -O arduino-1.6.4-linux32.tar.xz http://arduino.cc/download.php?f=/arduino-1.6.4-linux32.tar.xz &&
	 $SUDO tar xf arduino-1.6.4-linux32.tar.xz -C  /usr/local/ &&
	 $SUDO ln -sf /usr/local/arduino-1.6.4/arduino /usr/local/bin/) | save_log install_arduino
	verify_success
    fi
}

function install_GAE() {
    if [ -d /usr/local/google_appengine ]; then
	banner "Found exsiting /usr/local/google_appengine. Skipping isntall." | save_log -a install_GAE
    else
	banner "Installing Google app engine..."
	
	(wget -O google_appengine_1.9.26.zip https://storage.googleapis.com/appengine-sdks/featured/google_appengine_1.9.26.zip &&
	 unzip google_appengine_1.9.26.zip &&
	 $SUDO mv google_appengine /usr/local/ &&
	 $SUDO bash -c 'echo PATH=\$PATH:/usr/local/google_appengine >> /etc/profile') | save_log install_GAE
	verify_success
    fi
}


function fix_up() {
    # apt-get uses a non-standard name for the nodejs executable, which causes problems.
    ($SUDO ln -sf `which nodejs` /usr/local/bin/node 
     $SUDO chown -R gadgetron ~/.npm
     $SUDO chgrp -R gadgetron ~/.npm) 2>&1 | save_log fix_up
}
