#!/bin/bash
set -euo pipefail

USERNAME="lnsw"
USERID=900
# Marble LS pub key
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhejUPFR+fFUPFs3pulV0QNd1u2+Z5U769aWDVwsEcX nsoadmin@marble"
HOME_DIR="/home"
AUTHORIZED_KEYS_DIR="$HOME_DIR/$USERNAME/.ssh"
AUTHORIZED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/authorized_keys"
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"

# Test for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting." >&2
    exit 1
fi

# Test to see if /etc/sudoers.d does not exist
if ! test -d "/etc/sudoers.d"; then
    echo "Directory \"/etc/sudoers.d/\" does not exist. Exiting." >&2
    exit 1
fi

# Test to see if sudoers file for user has already been created
if test -f $SUDOERS_FILE; then
    echo "File \"$SUDOERS_FILE\" already exists. Exiting." >&2
    exit 1
fi

# Test to see if user already exists
if id $USERNAME >/dev/null 2>&1; then
    echo "User \"$USERNAME\" already exists. Exiting." >&2
    exit 1
fi

# Test if /home/$USERNAME already exists
if test -d /home/$USERNAME; then
    echo "Directory /home/\"$USERNAME\" already exists. Exiting." >&2
    exit 1
fi

# Test if /usr/home/$USERNAME already exists
if test -d /usr/home/$USERNAME; then
    echo "Directory /usr/home/\"$USERNAME\" already exists. Exiting." >&2
    exit 1
fi

# Test if UID is in already use.
if getent passwd $USERID >/dev/null 2>&1; then
    echo "UID $USERID is in use. Exiting." >&2
    exit 1
fi

# Test if sshd is running.
if ! pgrep -x "sshd" > /dev/null; then
  echo "Process sshd is not running. Exiting." >&2
  exit 1
fi

# Some machines use autofs to mount /home, so we can't write to them directly. On these machines, we've opted to use /usr/home for local/service accounts.
HOME_WRITEABLE=true

# Test to see if /home does not exist
if ! test -d "/home"; then
    echo "Directory \"/home\" does not exist. Testing for \"/usr/home\"." >&2
    HOME_WRITEABLE=false
fi

# Test for writable /home
if ! touch "/home/.lnswtest"; then
    echo "Directory \"/home\" is not writable. This is likely due to /home being mounted by autofs. Testing for \"/usr/home\"." >&2
    HOME_WRITEABLE=false
else
    # Clean up from the test.
    rm -f "/home/.lnswtest"
fi

# In the case that /home does not exist or is not writable, we check for /usr/home and create it if it does not exist.
if [ "$HOME_WRITEABLE" = false ]; then
    # Check to see if /usr exists.
    if ! test -d "/usr"; then
        echo "Directory \"/usr\" does not exist. This OS is strange. Exiting." >&2
        exit 1
    fi

    # Check for /usr/home. Create if it does not exist.
    if ! test -d "/usr/home"; then
        echo "Directory \"/usr/home\" does not exist. Creating it with 0755 permissions." >&2
        mkdir "/usr/home"
        chmod 0755 "/usr/home"
    else
      echo "Directory \"/usr/home\" exists. We will use that directory as the home." >&2
    fi

    # Update vars with correct home directory
    HOME_DIR="/usr/home"
    AUTHORIZED_KEYS_DIR="$HOME_DIR/$USERNAME/.ssh"
    AUTHORIZED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/authorized_keys"
fi

# Create system user with desired UID
setup_user()
{
    # Create system user with home directory.
    useradd -r -m -d "$HOME_DIR/$USERNAME" -c "Lansweeper account" -u $USERID -s /bin/bash "$USERNAME"
    # Create/set permissions for .ssh & .ssh/authorized_keys
    mkdir -p "$AUTHORIZED_KEYS_DIR"
    chmod 700 "$AUTHORIZED_KEYS_DIR"
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
    chown -R "$USERNAME:$USERNAME" "$AUTHORIZED_KEYS_DIR"

    # Add ssh key
    echo "$SSH_KEY" > "$AUTHORIZED_KEYS_FILE"
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
