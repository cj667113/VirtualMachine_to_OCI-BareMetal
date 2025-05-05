#!/bin/bash

# Backup original fstab
cp /etc/fstab /etc/fstab.bak

# Special case: handle /boot/efi without label
BOOT_UUID_LINE=$(grep -E "^[[:space:]]*UUID=[^[:space:]]+[[:space:]]+/boot/efi" /etc/fstab)
if [ -n "$BOOT_UUID_LINE" ]; then
    BOOT_UUID=$(echo "$BOOT_UUID_LINE" | awk '{print $1}' | cut -d= -f2)
    BOOT_DEV=$(blkid -U "$BOOT_UUID")

    if [ -z "$BOOT_DEV" ]; then
        echo "Warning: Could not resolve UUID=$BOOT_UUID for /boot/efi"
    else
        # Check if label already exists
        BOOT_LABEL=$(lsblk -no LABEL "$BOOT_DEV" | head -n1)
        if [ -z "$BOOT_LABEL" ]; then
            # Attempt to assign label (assumes vfat for /boot/efi)
            echo "Assigning label 'boot-efi' to $BOOT_DEV"
            fatlabel "$BOOT_DEV" boot-efi
            BOOT_LABEL="boot-efi"
        fi

        # Replace UUID with LABEL in /etc/fstab
        ESCAPED_UUID=$(echo "UUID=$BOOT_UUID" | sed 's/[]\/$*.^[]/\\&/g')
        ESCAPED_LABEL=$(echo "LABEL=$BOOT_LABEL" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "s|$ESCAPED_UUID|$ESCAPED_LABEL|" /etc/fstab
        echo "Updated /boot/efi line: replaced UUID=$BOOT_UUID with LABEL=$BOOT_LABEL"
    fi
fi

# General UUID -> LABEL or DEV (LVM) replacement
grep '^UUID=' /etc/fstab | while read -r line; do
    UUID=$(echo "$line" | awk '{print $1}' | cut -d= -f2)
    MOUNT=$(echo "$line" | awk '{print $2}')

    # Skip /boot/efi (already handled)
    [ "$MOUNT" = "/boot/efi" ] && continue

    DEV=$(blkid -U "$UUID")
    if [ -z "$DEV" ]; then
        echo "Warning: Could not resolve UUID=$UUID"
        continue
    fi

    # Get label
    LABEL=$(lsblk -no LABEL "$DEV" | head -n1)

    if [ -n "$LABEL" ]; then
        ESCAPED_UUID=$(echo "UUID=$UUID" | sed 's/[]\/$*.^[]/\\&/g')
        ESCAPED_LABEL=$(echo "LABEL=$LABEL" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "s|$ESCAPED_UUID|$ESCAPED_LABEL|" /etc/fstab
        echo "Replaced UUID=$UUID with LABEL=$LABEL for $MOUNT"
    fi

    # Check for LVM
    if [[ "$DEV" =~ /dev/mapper/ ]]; then
        CURRENT_ID=$(grep "$MOUNT" /etc/fstab | awk '{print $1}')
        ESCAPED_ID=$(echo "$CURRENT_ID" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "s|$ESCAPED_ID|$DEV|" /etc/fstab
        echo "Replaced $CURRENT_ID with $DEV for $MOUNT (LVM)"
    fi
done
