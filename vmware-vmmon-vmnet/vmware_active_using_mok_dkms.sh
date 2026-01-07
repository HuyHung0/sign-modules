#!/bin/bash

key_priv="/var/lib/dkms/mok.key"
key_pub="/var/lib/dkms/mok.pub"


# Sign the vmware modules with the new key.
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ${key_priv} ${key_pub} $(modinfo -n vmmon)
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ${key_priv} ${key_pub} $(modinfo -n vmnet)

sudo modprobe vmmon
sudo modprobe vmnet
