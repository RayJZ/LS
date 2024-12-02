```script
#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Variables
USERNAME="LS"
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4HExJ0ve3BT7tFAZMBNSK/e5PNVTlsWC6JUz18kxcJyexw15EPg6BcW15N0ygib94JpfMr8HBY+LIQPV0YkcUjqdjDzDX2vLrbm7kY4qQP6A2W2cck8/IXzdybCOLuP20xZ2uZaUKxXlqJPo2xHnVSNYVvUZP+S0TlVQNEPp46mPyWckV7GN1idAMbIvp1I39V+GWPSvb5vf92FTNR7xk0njgfPPVdujWghpn1WFQdTBEDT5lNpvKsCjyQTnV7WzN5Uq/SlC8olZwn0KZVSdwKtZKPQbzakgl2Wji1kYSWs69GcUMrUGCUB6uGy/nh5sfvzg2XrUu4ZRpkeBB+g5b0rkE3o00HdfaBG+u5vbyb67xNTen7MmN2CTualTcjL76KJZLATntusrNsZKMl0A+50477AqWPuceNPbh/FrC77HbLy3Ju+tP4fHFb1hvQxihDApLue6JKJKFXsNX4oLSHWWGxI1bjegGT+F+vyx8hpeDNSZmqtXIVtSnnj35EULSwmMLmpV7ujFh/HO+q9c5P5+nf2JFZt7G/6xUo4UtryIOMdyb/mT4asctgaMRJVTM64mP0uGLMxi/2d/h1f8bZkr4yhST27y83PDmyh2gRr9lnFievVK1Svlu2MzS7k2NQ+WuISxVUOj+7XLD/eGio5hKnMtigzoYYoRBoNZhSQ== nsoadmin@marble"
AUTHORIZED_KEYS_DIR="/home/$USERNAME/.ssh"
AUTHORIZED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/authorized_keys"
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"

# Function to create user and set up SSH key-based authentication
setup_user() {
    # Create the user and set their shell
    useradd -r -s /bin/bash "$USERNAME"
    echo "User $USERNAME created."

    # Create SSH directory and set permissions
    mkdir -p "$AUTHORIZED_KEYS_DIR"
    chmod 700 "$AUTHORIZED_KEYS_DIR"
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
    chown -R "$USERNAME:$USERNAME" "$AUTHORIZED_KEYS_DIR"
    echo "SSH directory and permissions set for $USERNAME."

	# Add ssh key
    echo "$SSH_KEY" > "$AUTHORIZED_KEYS_FILE"

    # Disable password auth
    passwd -l "$USERNAME"
}

setup_sudo() {
    cat > "$SUDOERS_FILE" << EOF
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/lspci, /usr/sbin/dmidecode, /usr/sbin/smbios, /usr/sbin/lvs, /usr/sbin/pvs, /usr/sbin/vgs, /usr/sbin/ifconfig, /usr/sbin/lshw
EOF
    chmod 440 "$SUDOERS_FILE"
    echo "Sudo privileges configured for $USERNAME."
}

# Main script execution
setup_user
setup_sudo

echo "User $USERNAME is set up with restricted sudo privileges and SSH key-based access only."
```
