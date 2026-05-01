#!/bin/bash

echo "🧹 Starting internal VM cleanup..."

# 1. Clean Package Caches
echo "--> Cleaning apt cache..."
sudo apt-get autoremove -y && sudo apt-get clean

# 2. Clean Docker (if you use it)
if [ -x "$(command -v docker)" ]; then
    echo "--> Cleaning Docker..."
    docker system prune -f
fi

# 3. Zero out the disk (The most important step for shrinking)
echo "--> Zeroing out free space (this may take a minute)..."
# This fills the disk until it's full, then deletes the file
dd if=/dev/zero of=/var/tmp/zero.fill bs=1M status=progress
rm /var/tmp/zero.fill

echo "--> Syncing..."
sync

echo "✅ Internal cleanup done. Shutting down in 5 seconds..."
sleep 5
sudo shutdown -h now
