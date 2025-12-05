#!/bin/bash

filename_key="vmware_key"
key_der="./${filename_key}.der"

# If the key already exists in the current directory, delete it from the MOK list.
if [ -f "$key_der" ]; then
    echo "Key file ${filename_key}.der exists. Removing it from the MOK list."
    sudo mokutil --delete "$key_der"
else
    echo "Key file ${filename_key}.der does not exist. No key to remove from the MOK list."
fi

# Generate a new key pair.
sudo openssl req -new -x509 -newkey rsa:2048 -keyout ${filename_key}.priv -outform DER -out ${filename_key}.der -noenc -days 36500 -subj "/CN=VMware/"

# Sign the vmware modules with the new key.
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ./${filename_key}.priv ./${filename_key}.der $(modinfo -n vmmon)
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ./${filename_key}.priv ./${filename_key}.der $(modinfo -n vmnet)

# Import the new key into MOK.
sudo mokutil --import ${filename_key}.der

echo "Now it's time for reboot, remember the password. You will get a blue screen after reboot choose 'Enroll MOK' -> 'Continue' -> 'Yes' -> 'enter password' -> 'OK' or 'REBOOT' "
