#!/bin/bash

cd /sys/kernel/config/usb_gadget/
mkdir -p g1
cd g1

echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # Version 1.0.0
echo 0x0200 > bcdUSB # USB 2.0

# Define device descriptors
mkdir -p strings/0x409
echo "serialnumber" > strings/0x409/serialnumber
echo "manufacturer" > strings/0x409/manufacturer
echo "Composite Gadget" > strings/0x409/product

# Configure the network function (g_ether)
mkdir -p functions/ecm.usb0
HOST="00:dc:c8:f7:75:14" # Set to your host's MAC address
SELF="00:dd:dc:eb:6d:a1" # Set to a unique MAC address for the device
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr

# Configure the MIDI function (g_midi)
mkdir -p functions/midi.gs0
echo 1 > functions/midi.gs0/in_ports
echo 1 > functions/midi.gs0/out_ports

# Create a configuration instance and bind the functions
mkdir -p configs/c.1
ln -s functions/ecm.usb0 configs/c.1/
ln -s functions/midi.gs0 configs/c.1/

# Bind the USB gadget to the UDC driver
echo "$(ls /sys/class/udc)" > UDC
