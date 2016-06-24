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
# :version: 0.0.1
##############################################################################

# Verify that script is running as root

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Set password authentication to no

sed '$ a PasswordAuthentication no' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Set challenge response authentication to no

sed '$ a ChallengeResponseAuthentication no' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	PasswordAuthentication no' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	ChallengeResponseAuthentication no' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Set public key authentication to yes && select algorithms

sed '$ a PubkeyAuthentication yes' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	PubkeyAuthentication yes' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	HostAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Set key exchange algorithms

sed '$ a KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a # Github needs diffie-hellman-group-exchange-sha1 some of the time but not always.' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host github.com' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a 	KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Remove prime numbers with size in bits < 2000

if test -e /etc/ssh/moduli ; then
	awk '$5 > 2000' /etc/ssh/moduli > "~/moduli"
	wc -l "~/moduli" # make sure there is something left
	mv "~/moduli" /etc/ssh/moduli
else
	ssh-keygen -G /etc/ssh/moduli.all -b 4096
	ssh-keygen -T /etc/ssh/moduli.safe -f /etc/ssh/moduli.all
	mv /etc/ssh/moduli.safe /etc/ssh/moduli
	rm /etc/ssh/moduli.all
fi

# Generate client ssh keys

ssh-keygen -t ed25519 -o -a 100
ssh-keygen -t rsa -b 4096 -o -a 100

# Set preferred symmetric ciphers and modes

sed '$ a Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Set preferred MACs

sed '$ a MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Turn off UseRoaming

sed '$ a Host *' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

sed '$ a	UseRoaming no' /etc/ssh/ssh_config > /etc/ssh/ssh_config.secure

# Replace old ssh_config with new ssh_config.secure

rm /etc/ssh/ssh_config

mv /etc/ssh/ssh_config.secure /etc/ssh/ssh_config
