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
            # Assign label in uppercase (FAT labels should be uppercase)
            echo "Assigning label 'BOOT-EFI' to $BOOT_DEV"
            fatlabel "$BOOT_DEV" BOOT-EFI
            BOOT_LABEL="BOOT-EFI"
        fi

        # Replace UUID with LABEL in /etc/fstab
        ESCAPED_UUID=$(printf 'UUID=%s' "$BOOT_UUID" | sed 's/[\/&]/\\&/g')
        ESCAPED_LABEL=$(printf 'LABEL=%s' "$BOOT_LABEL" | sed 's/[\/&]/\\&/g')
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
        ESCAPED_UUID=$(printf 'UUID=%s' "$UUID" | sed 's/[\/&]/\\&/g')
        ESCAPED_LABEL=$(printf 'LABEL=%s' "$LABEL" | sed 's/[\/&]/\\&/g')
        sed -i "s|$ESCAPED_UUID|$ESCAPED_LABEL|" /etc/fstab
        echo "Replaced UUID=$UUID with LABEL=$LABEL for $MOUNT"
    fi

    # Check for LVM and replace with device path
    if [[ "$DEV" =~ /dev/mapper/ ]]; then
        CURRENT_ID=$(grep -E "[[:space:]]+$MOUNT([[:space:]]+|$)" /etc/fstab | awk '{print $1}')
        ESCAPED_ID=$(printf '%s' "$CURRENT_ID" | sed 's/[\/&]/\\&/g')
        ESCAPED_DEV=$(printf '%s' "$DEV" | sed 's/[\/&]/\\&/g')

        if [[ "$CURRENT_ID" != "$DEV" && -n "$CURRENT_ID" ]]; then
            sed -i "s|$ESCAPED_ID|$ESCAPED_DEV|" /etc/fstab
            echo "Replaced $CURRENT_ID with $DEV for $MOUNT (LVM)"
        fi
    fi
done
