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
# :date: 24 July 2016
# :version: 0.0.5
##############################################################################

# Define variables (edit these if you want to test this script without altering your ssh_config)

SSH_CONFIG="/etc/ssh/ssh_config"

BACKUP_SSH_CONFIG="/etc/ssh/ssh_config.bak"

SECURE_SSH_CONFIG="/etc/ssh/ssh_config.secure"

MODULI="/etc/ssh/moduli"

BACKUP_MODULI="/etc/ssh/moduli.bak"

ALL_MODULI="/etc/ssh/moduli.all"

SAFE_MODULI="/etc/ssh/moduli.safe"

# Prompt the user for root

[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Backup current ssh configuration file

cp $SSH_CONFIG $BACKUP_SSH_CONFIG

# Create new ssh config file

echo -e "    PasswordAuthentication no \n    ChallengeResponseAuthentication no \n    Host * \n          PasswordAuthentication no \n          ChallengeResponseAuthentication no \n    PubkeyAuthentication yes \n    Host * \n           PubkeyAuthentication yes \n           HostAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa \n    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256 \n#   Github needs diffie-hellman-group-exchange-sha1 some of the time but not always. \n    Host github.com \n           KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1 \n    Host * \n           KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256 \n    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr \n    Host * \n           Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr \n    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com \n    Host * \n           MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com \n    HashKnownHosts yes \n    UseRoaming no \n    Host * \n           UseRoaming no" > $SECURE_SSH_CONFIG

# Examine existing ssh_config and promt user to select changes

if grep -Fxq "PasswordAuthentication yes" $SSH_CONFIG ; then
        while true; do
                read -p "Password Authentication is set to \"yes\". Change to \"no\" (strongly recommended)?" yn
                case $yn in
                        [Yy]* ) exit ;;
                        [Nn]* ) sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' $SECURE_SSH_CONFIG ;;
                        * ) echo "Please answer y (yes) or n (no).";;
                esac
        done
else echo "Password Authentication is set to \"no\". This is the recommended setting."

fi

if grep -Fxq "ChallengeResponseAuthentication yes" $SSH_CONFIG ; then
        while true; do
                read -p "Challenge Response Authentication is set to \"yes\". Change to \"no\" (strongly recommended)?" yn
                case $yn in
                        [Yy]* ) exit ;;
                        [Nn]* ) sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' $SECURE_SSH_CONFIG ;;
                        * ) echo "Please answer y (yes) or n (no).";;
                esac
        done
else echo "Challenge Response Authentication is set to \"no\". This is the recommended setting."

fi

if grep -Fxq "PubkeyAuthentication no" $SSH_CONFIG ; then
        while true; do
                read -p "Pubkey Authentication is set to \"no\". Change to \"yes\" (strongly recommended)?" yn
                case $yn in
                        [Yy]* ) exit ;;
                        [Nn]* ) sed -i 's/PubkeyAuthentication yes/ChallengeResponseAuthentication no/g' $SECURE_SSH_CONFIG ;;
                        * ) echo "Please answer y (yes) or n (no).";;
                esac
        done
else echo "Pubkey Authentication is set to \"yes\". This is the recommended setting."

fi

if grep -Fxq "HashKnownHosts no" $SSH_CONFIG ; then
        while true; do
                read -p "Hash Known Hosts is set to \"no\". Change to \"yes\" (strongly recommended)?" yn
                case $yn in
                        [Yy]* ) exit ;;
                        [Nn]* ) sed -i 's/HashKnownHosts yes/HashKnownHosts no/g' $SECURE_SSH_CONFIG ;;
                        * ) echo "Please answer y (yes) or n (no).";;
                esac
        done
else echo "Hash Known Hosts is set to \"yes\". This is the recommended setting."

fi

if grep -Fxq "UseRoaming yes" $SSH_CONFIG ; then
        while true; do
                read -p "Use Roaming is set to \"yes\". Change to \"nos\" (strongly recommended)?" yn
                case $yn in
                        [Yy]* ) exit ;;
                        [Nn]* ) sed -i 's/HashKnownHosts no/HashKnownHosts yes/g' $SECURE_SSH_CONFIG ;;
                        * ) echo "Please answer y (yes) or n (no).";;
                esac
        done
else echo "Use Roaming is set to \"no\". This is the recommended setting."

fi

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

# Display changes

while true; do
    read -p "Do you want to view your selected changes to ssh_config before committing to those changes?" yn
    case $yn in
        [Yy]* ) cat $SECURE_SSH_CONFIG; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y (yes) or n (no).";;
    esac
done

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
