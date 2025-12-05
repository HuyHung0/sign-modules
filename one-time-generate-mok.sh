# 1. Create a safe place for the key (root only)
sudo mkdir -p /root/mok
sudo chmod 700 /root/mok
cd /root/mok

# 2. Generate keypair (valid ~100 years)
sudo openssl req -new -x509 -newkey rsa:2048 -nodes \
  -keyout module-signing.key -out module-signing.crt \
  -days 36500 -subj "/CN=Local Module Signing/"

# 3. Lock down the private key
sudo chmod 600 /root/mok/module-signing.key

# 4. Enroll the public cert into MOK (you'll be asked to set a temporary password)
sudo mokutil --import /root/mok/module-signing.crt
