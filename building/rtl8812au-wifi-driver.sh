#!/bin/bash
# This comes from:
#
#   https://sites.google.com/site/easylinuxtipsproject/reserve-7#TOC-Realtek-RTL8812AU-chipset-0bda:8812-
#
# That site was found by plugging in the wifi USB stick, then
# running `lsusb` in the terminal to find the ID 0bda:8812, then
# doing a google search 'linux 0bda:8812'.
#
# Note: this must be run each time the kernel is updated!

#Realtek RTL8812AU chipset (0bda:8812)
# 5. For the Realtek RTL8812AU chipset, you have to install a
# driver. You can proceed like this:

# a. First establish internet connection by other means, for ex-
# ample by ethernet cable.

# b. Unplug the wifi adapter with this chipset, from your com-
# puter.

# d. Copy/paste the following command line into the terminal, in
# order to install the required build packages (the building
# tools with which you're going to build the driver). This is one
# line:

sudo apt install linux-headers-$(uname -r) build-essential git

# e. Download the driver packages by means of git, with this com-
# mand (use copy/paste):

cd /tmp
rm -rf rtl8812AU-driver-5.2.20
git clone https://github.com/zebulon2/rtl8812AU-driver-5.2.20

# f. Now you're going to compile the required kernel module from
# the driver packages. Copy/paste this line into the terminal, in
# order to enter the folder with the driver packages:

cd rtl8812AU-driver-5.2.20
make -j4
sudo make install

# h. At this stage you'll need to tweak Network Manager. Copy/-
# paste the following line into the terminal:

xed admin:///etc/NetworkManager/NetworkManager.conf

# In that text file, add the following two lines (use copy/-
# paste).  Though note that they may already be there:
#
#    [device]
#    wifi.scan-rand-mac-address=no

#i. Reboot your computer.
#j. Plug in your wifi adapter. It should work now.
