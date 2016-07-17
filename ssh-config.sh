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
# :date: 23 June 2016
# :version: 0.0.2
##############################################################################

# Prompt the user for root

[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Backup current ssh configuration file

cp /etc/ssh/ssh_config /etc/ssh/ssh_config.bak

# Set password authentication to no

sed '$ a PasswordAuthentication no' /etc/ssh/ssh_config | \

# Set challenge response authentication to no

sed '$ a ChallengeResponseAuthentication no' | \

sed '$ a Host *' | \

sed '$ a	PasswordAuthentication no' | \

sed '$ a	ChallengeResponseAuthentication no' | \

# Set public key authentication to yes && select algorithms

sed '$ a PubkeyAuthentication yes' | \

sed '$ a Host *' | \

sed '$ a	PubkeyAuthentication yes' | \

sed '$ a	HostAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa' | \

# Set key exchange algorithms

sed '$ a KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256' | \

sed '$ a # Github needs diffie-hellman-group-exchange-sha1 some of the time but not always.' | \

sed '$ a Host github.com' | \

sed '$ a 	KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1' | \

sed '$ a Host *' | \

sed '$ a	KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256' | \

# Set preferred symmetric ciphers and modes

sed '$ a Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' | \

sed '$ a Host *' | \

sed '$ a	Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' | \

# Set preferred MACs

sed '$ a MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com' | \

sed '$ a Host *' | \

sed '$ a	MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com' | \

# Turn off UseRoaming

sed '$ a Host *' | \

sed '$ a	UseRoaming no' > /etc/ssh/ssh_config.secure

# Remove prime numbers with size in bits < 2000

if test -e /etc/ssh/moduli ; then
	cp /etc/ssh/moduli /etc/ssh/moduli.bak
	awk '$5 > 2000' /etc/ssh/moduli > "${HOME}/moduli"
	wc -l "${HOME}/moduli" # make sure there is something left
	mv "${HOME}/moduli" /etc/ssh/moduli
else
	ssh-keygen -G /etc/ssh/moduli.all -b 4096
	ssh-keygen -T /etc/ssh/moduli.safe -f /etc/ssh/moduli.all
	mv /etc/ssh/moduli.safe /etc/ssh/moduli
	rm /etc/ssh/moduli.all
fi

# Prompt user to save changes

while true; do
    read -p "Do you want to commit changes made to ssh_config (your previous configuration will be saved at /etc/ssh/ssh_config.bak)?" yn
    case $yn in
        [Yy]* ) mv /etc/ssh/ssh_config.secure /etc/ssh/ssh_config; break;;
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
