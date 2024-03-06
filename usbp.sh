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
  info "Checking if already enabling access over USB..."
  if sudo test -f /root/usb.sh; then
    info "Already enabled"
    return
  elif sudo test ! -f /boot/config.txt; then
    info "Skipped due to missing boot files"
    return
  fi
  step "Enabling access over USB..."

  if ! sudo grep -q 'dtoverlay=dwc2' /boot/config.txt; then
    sudo sed -i '$a dtoverlay=dwc2' /boot/config.txt
  fi
  if ! sudo grep -q 'modules-load=dwc2' /boot/cmdline.txt; then
    sudo sed -i '$s/$/ modules-load=dwc2/g' /boot/cmdline.txt
  fi
  sudo touch /boot/ssh
  if ! sudo grep -q 'libcomposite' /etc/modules; then
    sudo sed -i '$a libcomposite' /etc/modules
  fi
  if ! sudo grep -q 'denyinterfaces usb0' /etc/dhcpcd.conf; then
    sudo sed -i '$a denyinterfaces usb0' /etc/dhcpcd.conf
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
