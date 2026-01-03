#!/bin/bash

filename_key="r8168_key"
key_priv="./${filename_key}.priv"
key_der="./${filename_key}.der"

# If the key does not exist, create a new key pair.
if [ ! -f "$key_der" ]; then
    echo "Key file ${filename_key}.der does not exist. Creating a new key pair."
    sudo openssl req -new -x509 -newkey rsa:2048 -keyout ${filename_key}.priv -outform DER -out ${filename_key}.der -noenc -days 36500 -subj "/CN=Realtek-r8168/"
else
    echo "Key file ${filename_key}.der exists. Using existing key."
fi

# Sign the r8168 module with the key.
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ${key_priv} ${key_der} $(modinfo -n r8168)

# Import the key into MOK.
sudo mokutil --import ${key_der}

echo "Now it's time for reboot, remember the password. You will get a blue screen after reboot choose 'Enroll MOK' -> 'Continue' -> 'Yes' -> 'enter password' -> 'OK' or 'REBOOT' "
