#!/bin/bash

if [ "$UID" -ne 0 ]; then
  sudo "$0" "$@"
  exit
fi

OPENBTS="/home/openbts/openbts/openbts"
USRP1_1="Ettus USRP1, single daughterboard"
USRP1_2="Ettus USRP1, two daughterboards"
RAD1="Range RAD1"
USRP2_N="Ettus USRP2 or N200 series"
USRPB_E="Ettus B100 or E100 series"
UMTRX="Fairwaves UmTRX"

install_gnuradio () {
  xterm -e "cd /home/openbts
  tar zxvf files/gnuradio-3.4.2-built.tar.gz
  cd gnuradio-3.4.2
  #./configure --disable-all-components --enable-usrp --enable-gruel
  #make
  make install
  
  if ! grep -q usrp /etc/group; then
    /usr/sbin/groupadd usrp
  fi
  
  if ! grep -q usrp.*openbts /etc/group; then
    /usr/sbin/usermod -a -G usrp openbts
  fi
  
  echo 'SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"fffe\", ATTRS{idProduct}==\"0002\", MODE:=\"0666\"' > /etc/udev/rules.d/10-usrp.rules
  echo 'SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"2500\", ATTRS{idProduct}==\"0002\", MODE:=\"0666\"' >> /etc/udev/rules.d/10-usrp.rules
  chown root:root /etc/udev/rules.d/10-usrp.rules"
}
  
install_uhd () {
  xterm -e "dpkg -i /home/openbts/files/uhd_003.005.001-release_i386.deb"
}

install_uhd_fairwaves () {
  xterm -e "cd /home/openbts
  tar zxvf files/UHD-Fairwaves-fairwaves-umtrx-built.tar.gz
  cd UHD-Fairwaves-fairwaves-umtrx/host/build
  #mkdir build
  #cd build
  #cmake ../
  #make
  make install
  ldconfig"
}

link_transceiver_RAD1 () {
  cd /home/openbts/openbts/openbts/trunk/apps
  make
  [ -L transceiver ] && rm transceiver
  [ -L ezusb.ihx ] && rm ezusb.ihx
  [ -L fpga.rbf ] && rm fpga.rbf
  ln -s ../TranceiverRAD1/transceiver .
  ln -s ../TranceiverRAD1/ezusb.ihx .
  ln -s ../TranceiverRAD1/fpga.rbf .
}

link_transceiver_USRP1 () {
  cd /home/openbts/openbts/openbts/trunk/apps
  [ -L transceiver ] && rm transceiver
  ln -s ../Transceiver52M/transceiver .
  mkdir -p /usr/local/share/usrp/rev4/ || true
  cp ../Transceiver52M/std_inband.rbf /usr/local/share/usrp/rev4/
}

link_transceiver_UHD () {
  cd /home/openbts/openbts/openbts/trunk/apps
  [ -L transceiver ] && rm transceiver
  ln -s ../Transceiver52M/transceiver .
}

install_everything () {
  echo "# Installing driver"
  echo 20
  $1
  echo 40
  echo "# Configuring OpenBTS"
  xterm -e "cd $OPENBTS/trunk
  autoreconf -i
  ./configure $2"
  echo 50
  echo "# Installing OpenBTS"
  xterm -e "make"
  echo 70
  echo "# Linking transceiver"
  link_transceiver_$3
}

selection=$(zenity --list \
  --height=350 \
  --title="Commotion-OpenBTS" \
  --text="Welcome to Commotion-OpenBTS! In order to get started, we \n\
need to know what kind of GSM hardware you are using to run \n\
your basestation. Choose one of the following options:" \
  --radiolist \
  --column="Selection" --column="Device" \
  . "$USRP1_1" \
  . "$USRP1_2" \
  . "$RAD1" \
  . "$USRP2_N" \
  . "$USRPB_E" \
  . "$UMTRX" \
  . "Other")

[ $? == 0 -a "$selection" != "" ] || exit 1
  
[ "$selection" == "Other" ] && zenity --warning --text="I'm sorry, but we don't support your device. You'll have to install OpenBTS manually for your device." && exit

(  # Begin zenity progress dialogue

  echo "# Extracting source code"
  echo 10
  cd /home/openbts
  tar zxvf files/openbts.tar.gz

  if [ "$selection" == "$USRP1_1" ]; then  # USRP1
    install_everything "install_gnuradio" "--with-usrp1 --with-singledb" "USRP1"
  elif [ "$selection" == "$USRP1_2" ]; then  # USRP1, 2xdaughterboard
    install_everything "install_gnuradio" "--with-usrp1" "USRP1"
  elif [ "$selection" == "$RAD1" ]; then  # RAD1
    install_everything "" "" "RAD1"
  elif [ "$selection" == "$USRP2_N" ]; then  # USRP2, N200
    # install UHD libraries
    install_everything "install_uhd" "--with-uhd --with-resamp" "UHD"
  elif [ "$selection" == "$USRPB_E" ]; then  # B100, E100
    # install UHD libraries
    install_everything "install_uhd" "--with-uhd" "UHD"
  elif [ "$selection" == "$UMTRX" ]; then  # UmTRX
    # install special UHD: https://github.com/fairwaves/UHD-Fairwaves
    install_everything "install_uhd_fairwaves" "--with-uhd" "UHD"
  fi
  
  echo 75
  echo "# Initializing OpenBTS database"
  cd $OPENBTS/trunk/
  mkdir /etc/OpenBTS || true
  [ -f /etc/OpenBTS/OpenBTS.db ] || sqlite3 -init ./apps/OpenBTS.example.sql /etc/OpenBTS/OpenBTS.db ".quit"
  
  echo 80
  echo "# Initializing Subscriber Registry"
  cd ../../subscriberRegistry/trunk/configFiles/
  mkdir -p /var/lib/asterisk/sqlite3dir || true
  [ -f /var/lib/asterisk/sqlite3dir/sqlite3.db ] || sqlite3 -init subscriberRegistryInit.sql /var/lib/asterisk/sqlite3dir/sqlite3.db ".quit"
  mkdir /var/run/OpenBTS || true

  echo 85
  echo "# Initializing Sipauthserve"
  cd ../
  make
  [ -f /etc/OpenBTS/sipauthserve.db ] || sqlite3 -init sipauthserve.example.sql /etc/OpenBTS/sipauthserve.db ".quit"
  
  echo 90
  echo "# Successfully built OpenBTS. Setting hostname..."
  UUID=`ip link |grep -v LOOPBACK |grep -A 1 -m 1 UP |tail -1 |awk '{print $2 }' | awk -F ':' '{ printf("%03d%03d%03d","0x"$4,"0x"$5,"0x"$6) }'`
  hostname="commotion-$UUID"
  echo "$hostname" > /etc/hostname
  echo "$hostname" > /proc/sys/kernel/hostname
  sed -i -e s/openbts/$hostname/g /etc/hosts

  echo 95
  echo "# Initializing Serval keyring..."
  [ `/home/openbts/serval-dna/servald keyring list` ] || /home/openbts/serval-dna/servald keyring add
  SID=`/home/openbts/serval-dna/servald keyring list |cut -d ':' -f 1`
  /home/openbts/serval-dna/servald set did $SID $UUID $hostname

  rm /home/openbts/.config/autostart/install-openbts.desktop
  rm /home/openbts/Desktop/install-openbts.sh
  mv /home/openbts/rc.local /etc/rc.local
  sed -i s/"openbts ALL=(ALL) NOPASSWD:ALL"/""/ /etc/sudoers
  echo "# Congratulations! Your basestation is now configured and running!"
  
) | zenity --progress --width=600 --percentage=0 --title="Installing Commotion-OpenBTS. This may take several minutes..." --text="Initializing installation..."

[ $? == 0 ] || exit 1

/etc/rc.local

exit