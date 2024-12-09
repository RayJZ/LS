#!/bin/bash

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

USERNAME="lnsw"
# Marble LS pub key
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhejUPFR+fFUPFs3pulV0QNd1u2+Z5U769aWDVwsEcX nsoadmin@marble"
AUTHORIZED_KEYS_DIR="/home/$USERNAME/.ssh"
AUTHORIZED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/authorized_keys"
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"

setup_user()
{
    
    if id $USERNAME >/dev/null 2>&1; then
        echo "User \"$USERNAME\"already exists, exiting." >&2
        exit 1
    fi
    
    if test -d /home/$USERNAME; then
        echo "Directory  /home/\"$USERNAME\"already exists, exiting." >&2
        exit 1
    fi
    
    # Create system user with home directory. Don't know if it needs to be bash but bash definitely works.
    useradd -r -m -u 900 -s /bin/bash "$USERNAME"
    # Create/set permissions for .ssh & .ssh/authorized_keys
    mkdir -p "$AUTHORIZED_KEYS_DIR"
    chmod 700 "$AUTHORIZED_KEYS_DIR"
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
    chown -R "$USERNAME:$USERNAME" "$AUTHORIZED_KEYS_DIR"

    # Add ssh key
    echo "$SSH_KEY" > "$AUTHORIZED_KEYS_FILE"

    # Disable password auth
    passwd -l "$USERNAME"
}

# Give sudo for least privilege commands
setup_sudo()
{
    cat > "$SUDOERS_FILE" << EOF
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/lspci, /usr/sbin/dmidecode, /usr/sbin/smbios, /usr/sbin/lvs, /usr/sbin/pvs, /usr/sbin/vgs, /usr/sbin/ifconfig, /usr/sbin/lshw
EOF
    chmod 440 "$SUDOERS_FILE"
}

setup_user
setup_sudo
