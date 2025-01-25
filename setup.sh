#!/bin/bash

USERNAME="lnsw"
UID=900
# Marble LS pub key
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhejUPFR+fFUPFs3pulV0QNd1u2+Z5U769aWDVwsEcX nsoadmin@marble"
AUTHORIZED_KEYS_DIR="/home/$USERNAME/.ssh"
AUTHORIZED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/authorized_keys"
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"

# Test for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Test for /etc/sudoers.d
if ! test -d "/etc/sudoers.d"; then
    echo "Directory \"/etc/sudoers.d/\" does not exist, exiting." >&2
    exit 1
fi

# Test to see if sudo file for user has already been created
if test -d SUDOERS_FILE; then
    echo "File \"$SUDOERS_FILE\" already exists, exiting." >&2
    exit 1
fi

# Test to see if user already exists
if id $USERNAME >/dev/null 2>&1; then
    echo "User \"$USERNAME\" already exists, exiting." >&2
    exit 1
fi

# Test if user's home directory already exists
if test -d /home/$USERNAME; then
    echo "Directory /home/\"$USERNAME\" already exists, exiting." >&2
    exit 1
fi

# Test if UID is in already use.
if id $UID >/dev/null 2>&1; then
    echo "Default UID $UID is in use. Exiting." >&2
    exit 1
fi

# Test if sshd is running.
if ! pgrep -x "sshd" > /dev/null; then
  echo "Process sshd is not running. Exiting." >&2
  exit 1
fi

setup_user()
{
    # Create system user with home directory.
    useradd -r -m -u $UID -s /bin/bash "$USERNAME"
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

# Give passwordless sudo for least privilege commands
setup_sudo()
{
    cat > "$SUDOERS_FILE" << EOF
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/lspci, /usr/sbin/dmidecode, /usr/sbin/smbios, /usr/sbin/lvs, /usr/sbin/pvs, /usr/sbin/vgs, /usr/sbin/ifconfig, /usr/sbin/lshw
EOF
    chmod 440 "$SUDOERS_FILE"
}

setup_user
setup_sudo
echo "User \"$USERNAME\" setup successfully."
