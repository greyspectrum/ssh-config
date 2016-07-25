#!/bin/bash

##############################################################################
# ssh-config
# -----------
# Edits your ssh_config to set secure default ciphers, modes, MACs, & settings.
#
# Chosen defaults are based on original work by Stribika, available here:
#
# https://stribika.github.io/2015/01/04/secure-secure-shell.html
#
# :author: greyspectrum
# :date: 20 July 2016
# :version: 0.9.4
##############################################################################

# Define variables (edit these if you want to test this script without altering your ssh_config)

SSH_CONFIG="/etc/ssh/ssh_config"

BACKUP_SSH_CONFIG="/etc/ssh/ssh_config.bak"

SECURE_SSH_CONFIG="/etc/ssh/ssh_config.secure"

MODULI="/etc/ssh/moduli"

BACKUP_MODULI="/etc/ssh/moduli.bak"

ALL_MODULI="/etc/ssh/moduli.all"

SAFE_MODULI="/etc/ssh/moduli.safe"

# Introduce changes to the user and ask for confirmation before running

echo -e "This script will apply the following changes to ssh_config:\n\nKey Exchange Algorithms:\n-ECDH over Curve25519 with SHA2\n-Diffie Hellman Group Exchange with SHA2\n\nServer Authentication:\n-Ed25519 with SHA512\n-RSA with SHA1\n\nClient Authentication:\n-Password Authentication: no\n-Challenge Response Authentication: no\n-Public Key Authentication: yes\n\nHost Keys will be created, after an additional prompt, with Ed25519 and 4096 RSA. If you already have host keys, you may skip this step.\n\nSymmetric Ciphers & Modes of Operation:\n-Chacha20\n-AES 256, GCM\n-AES 128, GCM\n-AES 256, CTR\n-AES 192, CTR\n-AES 128, CTR\n\nMessage Authentication Codes:\n-hmac-sha2-512-etm\n-hmac-sha2-256-etm\n-hmac-ripemd160-etm\n-umac-128-etm\n-hmac-sha2-512\n-hmac-sha2-256\n-hmac-ripemd160\n-umac-128\n\nHashKnownHosts: yes\n\nUse Roaming: no\n\nInsecure options will be disabled. Your current ssh_config will be backed up at /etc/ssh/ssh_config.bak.\n"

while true; do
    read -p "Do you wish to apply these changes?" yn
    case $yn in
        [Yy]* ) echo -e "\nStarting ssh_config...\n"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y (yes) or n (no).";;
    esac
done

# Prompt the user for root

[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Backup current ssh configuration file

cp $SSH_CONFIG $BACKUP_SSH_CONFIG

# Create new ssh config file

echo -e "    PasswordAuthentication no \n    ChallengeResponseAuthentication no \n    Host * \n          PasswordAuthentication no \n          ChallengeResponseAuthentication no \n    PubkeyAuthentication yes \n    Host * \n           PubkeyAuthentication yes \n           HostAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa \n    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256 \n#   Github needs diffie-hellman-group-exchange-sha1 some of the time but not always. \n    Host github.com \n           KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1 \n    Host * \n           KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256 \n    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr \n    Host * \n           Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr \n    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com \n    Host * \n           MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com \n    HashKnownHosts yes \n    UseRoaming no \n    Host * \n           UseRoaming no" > $SECURE_SSH_CONFIG

# Remove prime numbers with size in bits < 2000

if test -e $MODULI ; then
	cp $MODULI $BACKUP_MODULI
	awk '$5 > 2000' $MODULI > "${HOME}/moduli"
	wc -l "${HOME}/moduli" # make sure there is something left
	mv "${HOME}/moduli" $MODULI
else
	ssh-keygen -G $ALL_MODULI -b 4096
	ssh-keygen -T $SAFE_MODULI -f $ALL_MODULI
	mv $SAFE_MODULI $MODULI
	rm $ALL_MODULI
fi

# Prompt user to save changes

while true; do
    read -p "Do you want to commit changes made to ssh_config (your previous configuration will be saved at /etc/ssh/ssh_config.bak)?" yn
    case $yn in
        [Yy]* ) mv $SECURE_SSH_CONFIG $SSH_CONFIG; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y (yes) or n (no).";;
    esac
done

# Generate client ssh keys

while true; do
    read -p "Do you want to generate ssh keys now?" yn
    case $yn in
        [Yy]* ) ssh-keygen -t ed25519 -o -a 100
		ssh-keygen -t rsa -b 4096 -o -a 100; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y (yes) or n (no).";;
    esac
done
