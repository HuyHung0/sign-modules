# README

## New version

Ideas:
- Create one time MOK key pair and enroll it.
- Add a post install hook to sign modules for every new kernel

### Steps
#### One time MOK key pair creation and enrollment
Create directory to store MOK keys
```bash
sudo mkdir -p /root/mok
sudo chmod 700 /root/mok
cd /root/mok
```

Generate key pair (valid ~100 years):
```bash
sudo openssl req -new -x509 -newkey rsa:2048 -nodes \
  -keyout module-signing.key -out module-signing.crt \
  -days 36500 -subj "/CN=Local Module Signing/"
```

Lock the private key
```bash
sudo chmod 600 /root/mok/module-signing.key
```

Enroll the public cert into MOK
```bash
sudo mokutil --import /root/mok/module-signing.crt
```
#### Post install hook to sign modules
Create file `/etc/kernel/postinst.d/zz-sign-external`
```bash
#!/bin/sh
# Sign ONLY selected external modules for the NEWLY installed kernel version.
# Debian/Ubuntu calls this as: <script> <kernel-version> <arg>
set -eu

KVER="${1:-$(uname -r)}"

# Your persistent MOK key/certs
KEY="/root/mok/module-signing.key"      # PEM private key
CRT_PEM="/root/mok/module-signing.pem"  # PEM certificate for sign-file
CRT_DER="/root/mok/module-signing.der"  # optional DER

# Whitelist (module names)
ALLOW="vmmon vmnet evdi rtl88x2bu 88x2bu r8168"

log() { printf '%s\n' "$*" >&2; }

# Locate sign-file for this kernel
if [ -x "/usr/src/linux-headers-$KVER/scripts/sign-file" ]; then
  SIGN="/usr/src/linux-headers-$KVER/scripts/sign-file"
elif SIGN="$(command -v sign-file 2>/dev/null)"; then
  :
else
  SIGN="$(find /usr/lib -path "*/linux-kbuild-*/scripts/sign-file" 2>/dev/null | head -n1 || true)"
fi

[ -n "${SIGN:-}" ] && [ -x "$SIGN" ] || exit 0
[ -r "$KEY" ] || exit 0
[ -r "$CRT_PEM" ] || [ -r "$CRT_DER" ] || exit 0

sign_one_file() {
  f="$1"
  [ -f "$f" ] || return 0
  if [ -z "$(modinfo -F signer "$f" 2>/dev/null || true)" ]; then
    log "Signing: $f"
    if [ -r "$CRT_PEM" ]; then
      "$SIGN" sha256 "$KEY" "$CRT_PEM" "$f" 2>/dev/null || {
        log "WARN: PEM signing failed for $f, trying DER…"
        [ -r "$CRT_DER" ] && "$SIGN" sha256 "$KEY" "$CRT_DER" "$f" || log "WARN: DER signing also failed for $f"
      }
    else
      [ -r "$CRT_DER" ] && "$SIGN" sha256 "$KEY" "$CRT_DER" "$f" || log "WARN: no usable cert to sign $f"
    fi
  fi
}

# Use -k "$KVER" so we target the new kernel, not the running one
for m in $ALLOW; do
  modpath="$(modinfo -k "$KVER" -n "$m" 2>/dev/null || true)"
  if [ -n "$modpath" ]; then
    sign_one_file "$modpath"
  else
    log "Skipping (not found for $KVER): $m"
  fi
done

/sbin/depmod "$KVER" || true
exit 0

```

Make it executable:
```bash
sudo chmod +x /etc/kernel/postinst.d/zz-sign-external
```

#### How to test without waiting for another kernel update

You can simulate the postinst call for your current kernel:
```bash
KVER="$(uname -r)"
sudo bash -x /etc/kernel/postinst.d/zz-sign-external "$KVER"
```

Then check one module:
```bash
modinfo -F signer "$(modinfo -n -k "$KVER" rtl88x2bu)"   # or vmmon / r8168 / etc.
```

#### Looking for exist modules

```bash
└─$ KVER="$(uname -r)"
# If these print full paths, great; if they error, modules aren't built yet.
modinfo -n vmmon
modinfo -n vmnet

# Also look around just in case they landed in a different dir:
find /lib/modules/$KVER -type f -name 'vm*.ko*' 2>/dev/null

/lib/modules/6.1.0-40-amd64/misc/vmmon.ko
/lib/modules/6.1.0-40-amd64/misc/vmnet.ko
/lib/modules/6.1.0-40-amd64/misc/vmmon.ko
/lib/modules/6.1.0-40-amd64/misc/vmnet.ko
/lib/modules/6.1.0-40-amd64/kernel/net/vmw_vsock/vmw_vsock_vmci_transport.ko
/lib/modules/6.1.0-40-amd64/kernel/net/vmw_vsock/vmw_vsock_virtio_transport_common.ko
/lib/modules/6.1.0-40-amd64/kernel/net/vmw_vsock/vmw_vsock_virtio_transport.ko
/lib/modules/6.1.0-40-amd64/kernel/crypto/vmac.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/net/vmxnet3/vmxnet3.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/comedi/drivers/vmk80xx.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/scsi/vmw_pvscsi.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/misc/vmw_vmci/vmw_vmci.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/misc/vmw_balloon.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/video/fbdev/vermilion/vmlfb.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/gpu/drm/vmwgfx/vmwgfx.ko
/lib/modules/6.1.0-40-amd64/kernel/drivers/pci/controller/vmd.ko
```

## Old version
These scripts are for signing modules when the modules can not be loaded because of enabling secure boot. We need to install `openssl` and `mokutil` before running these scripts. The scripts will create two files with extensions `.der` and `.priv`. These files will be ignore by `git` in `.gitignore`.

- Sign `vmmon`, `vmnet` to run VMware on Debian with secure boot enable. The script is a copy from
<https://github.com/rune1979/ubuntu-vmmon-vmware-bash/tree/master>. However, we change the option `-nodes` (which is deprecated in `openssl`) to `-noenc`.
- Sign wifi driver `RTL88x2bu` after installing driver from <https://github.com/cilynx/rtl88x2bu>.
- Sign virtualbox modules: `vboxdrv`, `vboxnetflt`, `vboxnetadp` using instruction when running `sudo /sbin/vboxconfig`.

Example: Browser and save scripts manually or download using git or wget; make it executable and run it.
```bash
git clone https://github.com/huyhung0/sign-modules
cd sign-modules/wifi-rtl88x2bu
sudo chmod +x activate_wifi_88x2bu.sh
sudo ./activate_wifi_88x2bu.sh
```
Then input the password which will be used when sign after reboot. Reboot, choose 'Enroll MOK' -> 'Continue' -> 'Yes' -> 'enter password' -> 'OK' or 'REBOOT'.

Each time we upgrade linux kernel, we may need to re-run these scripts.
