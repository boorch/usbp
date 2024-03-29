#!/bin/sh

# Ensure the script fails on any errors
set -e

SUPPORT_DIR="$HOME/usbp/usb"

# Define simple logging functions
info() {
  echo "INFO: $*"
}

step() {
  echo "STEP: $*"
}

copy_as() {
  if ! sudo test -f "$1"; then
    sudo cp "$SUPPORT_DIR$1" "$1"
  fi
}

setup_usb_gadget() {

  info "Apt-Hold goddamn firmware updates so wi-fi doesn't break"
  sudo apt-mark hold firmware-atheros firmware-brcm80211 firmware-libertas firmware-misc-nonfree firmware-realtek
  info "Checking if already enabling access over USB..."
  if sudo test -f /root/usb.sh; then
    info "Already enabled"
    return
  elif sudo test ! -f /boot/config.txt; then
    info "Skipped due to missing boot files"
    return
  fi
  step "Enabling access over USB..."

  if ! sudo grep -q 'dtoverlay=dwc2' /boot/firmware/config.txt; then
    sudo sed -i '$a dtoverlay=dwc2' /boot/firmware/config.txt
  fi
  if ! sudo grep -q 'modules-load=dwc2' /boot/firmware/cmdline.txt; then
    sudo sed -i '$s/$/ modules-load=dwc2/g' /boot/firmware/cmdline.txt
  fi
  sudo touch /boot/ssh
  if ! sudo grep -q 'libcomposite' /etc/modules; then
    sudo sed -i '$a libcomposite' /etc/modules
  fi
  #if ! sudo grep -q 'denyinterfaces usb0' /etc/dhcpcd.conf; then
  #  sudo sed -i '$a denyinterfaces usb0' /etc/dhcpcd.conf
  #fi

  # Configuration as a string
  CONFIG="auto usb0
allow-hotplug usb0
iface usb0 inet static
    address 192.168.1.166
    netmask 255.255.255.0
    gateway 192.168.1.1"

  # File path
  FILE="/etc/network/interfaces.d/usb0"

  # Ensure the directory exists
  sudo mkdir -p $(dirname $FILE)

  # Check if the file already contains this exact configuration
  if ! sudo grep -Fxq "$CONFIG" $FILE; then
    # Backup the existing configuration file, if necessary
    sudo cp $FILE ${FILE}.bak || true  # Proceed if file does not exist

    # Update the file with the new configuration
    echo "$CONFIG" | sudo tee $FILE > /dev/null
    echo "Updated configuration for usb0."
  else
    echo "Configuration for usb0 already up to date."
  fi
  
  sudo mkdir -p /etc/dnsmasq.d
  sudo mkdir -p /etc/network/interfaces.d
  copy_as /etc/dnsmasq.d/usb
  copy_as /etc/network/interfaces.d/usb0
  copy_as /root/usb.sh
  sudo chmod 755 /root/usb.sh
  if ! sudo grep -q '/root/usb\.sh' /etc/rc.local; then
    sudo sed -i '$i sh /root/usb.sh\n' /etc/rc.local
  fi
}

# Call setup_usb_gadget directly
setup_usb_gadget
