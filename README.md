[![alt tag](http://img.shields.io/badge/maintainer-dismantl-green.svg)](https://github.com/dismantl)

Commotion-OpenBTS

==Introduction==

Commotion-OpenBTS is packaged as a customized x86 Ubuntu Linux distribution. 
It comes as a live image that can be booted from a USB drive or CD. This
repository contains resources used to create the Commotion-OpenBTS image.

The purpose of this software is to allow voice calls over a Commotion 
wireless mesh network. Phone calls can be made between GSM unlocked phones, 
or between GSM unlocked phones and phones meshing over WiFi with the Serval 
"Batphone" software.

In order to use Commotion-OpenBTS, you need a compatible GSM hardware
transceiver. Currently, compatible hardware includes the Range RAD1;
the Ettus USRP1, USRP2, N200 series, B100 series, and E100 series; and
the Fairwaves UmTRX.

==How to Run It==

To run Commotion-OpenBTS, download the ISO file at 
https://commotionwireless.net/download, and load it onto a USB drive using 
unetbootin, or your tool of choice. You can then boot from the USB drive 
with your laptop or desktop computer, with your GSM radio attached. Once 
the OS is loaded, a configuration wizard asks you what type of GSM hardware
you have, and configures the proper driver. After that, everything should be
running, and you can start making calls!

==Components==

Commotion-OpenBTS includes the following open source software components:
* OpenBTS (http://wush.net/trac/rangepublic/browser)
* OLSRd (http://olsr.org/git/?p=olsrd.git;a=summary)
* Serval (https://github.com/servalproject/serval-dna)
* Asterisk (http://www.asterisk.org/downloads/source-code)

==How to Build It==

The Commotion-OpenBTS image was built with the following process:
1. Fresh install of Ubuntu 12.04 LTS 32-bit
2. Install dependencies:
 * apt-get update && apt-get install autoconf libtool screen \
    libosip2-dev bison flex libldns-dev libortp-dev libusb-1.0-0-dev g++ \
    sqlite3 libsqlite3-dev libreadline6-dev libboost-all-dev subversion \
    git libxml2-dev
3. Get source code:
 * svn checkout http://svn.asterisk.org/svn/asterisk/branches/1.8 asterisk-1.8
 * svn co http://wush.net/svn/range/software/public openbts
 * git clone git://github.com/servalproject/serval-dna.git
 * git clone git://github.com/servalproject/app_servaldna.git
 * git clone git://github.com/opentechinstitute/olsrd.git
4. Build and install Asterisk
5. Build serval-dna
6. Build and install OLSRd (using example config in repo)
7. Build and configure app_servaldna (follwing steps here: 
   https://github.com/servalproject/serval-dna/blob/master/doc/OpenBts-setup.md)
8. Add the following to /etc/asterisk/extensions.conf:
        [phones]
        include => openbts
9. Build, install, and configure OpenBTS: 
    http://wush.net/trac/rangepublic/wiki/BuildInstallRun
10. Create /etc/rc.local script to start components on boot 
     (example rc.local included in repo)

==Further work==

The Open Technology Institute is supporting the development of the following
OpenBTS features by our partners:
* GPRS: https://github.com/chemeris/openbts-p2.8
* Handover: https://github.com/dmisol/openbts-p2.8/tree/handover

==Contact==

For questions, email Dan Staples <danstaples AT opentechinstitute DOT org>

Last updated: March 12, 2013
