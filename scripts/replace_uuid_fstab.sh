#!/bin/bash

# Backup original fstab
cp /etc/fstab /etc/fstab.bak

# Loop over each UUID in fstab
grep '^UUID=' /etc/fstab | while read -r line; do
    UUID=$(echo "$line" | awk '{print $1}' | cut -d= -f2)
    MOUNT=$(echo "$line" | awk '{print $2}')

    # Find device from UUID
    DEV=$(blkid -U "$UUID")
    if [ -z "$DEV" ]; then
        echo "Warning: Could not resolve UUID=$UUID"
        continue
    fi

    # Is it an LVM volume?
    if [[ "$DEV" =~ /dev/mapper/ ]]; then
        # Replace the line with LVM path
        ESCAPED_UUID=$(echo "UUID=$UUID" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "s|$ESCAPED_UUID|$DEV|" /etc/fstab
        echo "Replaced UUID=$UUID with $DEV for $MOUNT"
    fi
done
