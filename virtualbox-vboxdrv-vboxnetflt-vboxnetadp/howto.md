This is the instruction from virtualbox when running `sudo /sbin/vboxconfig`
```bash
sudo mkdir -p /var/lib/shim-signed/mok
sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
sudo reboot
```

After reboot, run again
```bash
sudo /sbin/vboxconfig
```

Note: I tried to use the same method when signing vmware but it was not working. The above method worked.