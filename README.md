These scripts are for signing modules when the modules can not be loaded because of enabling secure boot. We need to install `openssl` and `mokutil` before running these scripts. The scripts will create two files with extensions `.der` and `.priv`. These files will be ignore by `git` in `.gitignore`.

- Sign `vmmon`, `vmnet` to run VMware on Debian with secure boot enable. The script is a copy from 
<https://github.com/rune1979/ubuntu-vmmon-vmware-bash/tree/master>. However, we change the option `-nodes` (which is deprecated in `openssl`) to `-noenc`.
- Sign wifi driver `RTL88x2bu` after installing driver from <https://github.com/cilynx/rtl88x2bu>.

Example: Browser and save scripts manually or download using git or wget; make it executable and run it.
```bash
git clone https://github.com/huyhung0/sign-modules
cd sign-modules/wifi-rtl88x2bu
sudo chmod +x activate_wifi_88x2bu.sh 
sudo ./activate_wifi_88x2bu.sh
```
Then input the password which will be used when sign after reboot. Reboot, choose 'Enroll MOK' -> 'Continue' -> 'Yes' -> 'enter password' -> 'OK' or 'REBOOT'.

Each time we upgrade linux kernel, we may need to re-run these scripts.