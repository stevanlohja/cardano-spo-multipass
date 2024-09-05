#!/bin/bash

instances=("cn1" "cn2")

for instance in "${instances[@]}"; do
    echo "🚀 Running commands on $instance..."

    multipass exec "$instance" -- bash -c '
        ARCHIVE_URL="URL_TO_9_1_0.tar.zst"
        DEST_DIR="$HOME/.local/bin"
        mkdir -p "$DEST_DIR"
        echo "Downloading archive..."
        curl -L "$ARCHIVE_URL" -o 9_1_0.tar.zst
        if [ $? -ne 0 ]; then
            echo "Failed to download the archive."
            exit 1
        fi

        # Install zstd if not already installed
        if ! command -v zstd &> /dev/null; then
            sudo apt-get update -y
            sudo apt-get install -y zstd
        fi

        echo "Extracting archive..."
        # Extract using zstd and tar, stripping one level of directory
        zstd -d -c 9_1_0.tar.zst | tar -x -C "$DEST_DIR" --strip-components=1
        if [ $? -ne 0 ]; then
            echo "Failed to extract the archive."
            exit 1
        fi

        # Clean up
        rm 9_1_0.tar.zst

        echo "Archive downloaded and extracted successfully to $DEST_DIR"
    '

    echo "🎉 Finished running commands on $instance."
done