#!/bin/bash

filename_key="vmware_key"

if [ ! -f "${filename_key}.priv" ] || [ ! -f "${filename_key}.der" ]; then
    echo "Key files not found. Generating new key files and signing modules..."
    sudo openssl req -new -x509 -newkey rsa:2048 -keyout ${filename_key}.priv -outform DER -out ${filename_key}.der -noenc -days 36500 -subj "/CN=VMware/"
    sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ./${filename_key}.priv ./${filename_key}.der $(modinfo -n vmmon)
    sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ./${filename_key}.priv ./${filename_key}.der $(modinfo -n vmnet)
fi

sudo mokutil --import ${filename_key}.der
echo "Now it's time for reboot, remember the password. You will get a blue screen after reboot choose 'Enroll MOK' -> 'Continue' -> 'Yes' -> 'enter password' -> 'OK' or 'REBOOT' "
