#!/bin/bash

# Colors for echo
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "---------------------"
echo ""
echo "Oblivion Remastered optimization script for Steam Deck by krupar"
echo ""
echo "---------------------"
sleep 1
echo "---------------------"
echo ""
echo "Buy me a coffee @ https://ko-fi.com/krupar"
echo ""
echo "---------------------"
sleep 1

# Setup paths
SSD_OBLIVION_REMASTERED_COMPAT_DIR="$HOME/.steam/steam/steamapps/compatdata/2623190"
FOLDER_SUFFIX="pfx/drive_c/users/steamuser/Documents/My Games/Oblivion Remastered/Saved/Config/Windows"

# Detect SD card mount
SD_MOUNT=$(findmnt -rn -o TARGET | grep '/run/media' | sed 's/\\x20/ /g')

if [ -n "$SD_MOUNT" ]; then
    echo "SD Card is mounted at: $SD_MOUNT"
    SD_OBLIVION_REMASTERED_COMPAT_DIR="$SD_MOUNT/steamapps/compatdata/2623190"
fi

# Determine installation path
if [ -d "$SSD_OBLIVION_REMASTERED_COMPAT_DIR" ]; then
    echo "Oblivion Remastered installation found on Internal SSD."
    OBLIVION_REMASTERED_COMPAT_DIR="$SSD_OBLIVION_REMASTERED_COMPAT_DIR"
elif [ -n "$SD_MOUNT" ] && [ -d "$SD_OBLIVION_REMASTERED_COMPAT_DIR" ]; then
    echo "Oblivion Remastered installation found on SD Card."
    OBLIVION_REMASTERED_COMPAT_DIR="$SD_OBLIVION_REMASTERED_COMPAT_DIR"
else
    echo "ERROR: Oblivion Remastered installation not found."
    exit 1
fi

OBLIVION_REMASTERED_CONFIG_DIR="$OBLIVION_REMASTERED_COMPAT_DIR/$FOLDER_SUFFIX"
FILES=(
    "$OBLIVION_REMASTERED_CONFIG_DIR/GameUserSettings.ini"
    "$OBLIVION_REMASTERED_CONFIG_DIR/Engine.ini"
)

# Check if any of the existing files are immutable
files_immutable=false
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        attributes=$(lsattr "$FILE" 2>/dev/null | awk '{print $1}')
        if [[ $attributes == *i* ]]; then
            files_immutable=true
            echo "Detected immutable file: $FILE"
        fi
    fi
done

# If any file is immutable, ask for password and remove immutability
if $files_immutable; then
    zenity --info --title="Files are Immutable" --text="Some existing config files are read-only.\nYou must unlock them to update the preset.\n\nYou will be asked for your sudo password."

    # Check if the user has a sudo password
    PASS_STATUS=$(passwd -S "$USER" 2>/dev/null)
    STATUS=${PASS_STATUS:${#USER}+1:2}
    if [[ "$STATUS" == "NP" ]]; then
        zenity --info --title="No Password Set" --text="No sudo password is set.\nYou must set one now to continue."
        passwd
        echo "SUDO Password is now set for $USER."
    fi

    # Prompt for sudo password with retries
    while true; do
        SUDO_PASS=$(zenity --password --title="Enter SUDO Password to Unlock Files")

        if [ $? -ne 0 ]; then
            zenity --error --title="Cancelled" --text="Operation cancelled by user."
            exit 1
        fi

        echo "$SUDO_PASS" | sudo -S -v 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Password accepted."
            break
        else
            zenity --error --title="Incorrect Password" --text="Incorrect password. Try again."
        fi
    done

    # Remove immutable flag
    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            echo "$SUDO_PASS" | sudo -S chattr -i "$FILE"
            echo "Removed immutable from $FILE"
        fi
    done
fi

# Ask user for preset choice
preset_choice=$(zenity --list \
    --title="Oblivion Remastered Preset Selector" \
    --text="Which preset would you like to apply?" \
    --radiolist \
    --column="Select" --column="Preset" \
    TRUE "Performance" \
    FALSE "Quality" \
    FALSE "Restore Defaults" \
    --width=450 --height=350)

if [ $? -ne 0 ]; then
    echo "Cancel pressed. Exiting."
    exit 1
fi

case "$preset_choice" in
    "Performance")
        ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/performance.zip"
        ;;
    "Quality")
        ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/quality.zip"
        ;;
    "Restore Defaults")
        ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/restore_defaults.zip"
        ;;
    *)
        echo "Unknown option selected. Exiting."
        exit 1
        ;;
esac

echo "$preset_choice selected."

# Make sure the config directory exists
mkdir -p "$OBLIVION_REMASTERED_CONFIG_DIR"

# Download and unzip
TEMP_ZIP="$OBLIVION_REMASTERED_CONFIG_DIR/preset.zip"

echo "Downloading preset..."
curl -L -o "$TEMP_ZIP" "$ZIP_URL"

echo "Unzipping preset..."
unzip -o "$TEMP_ZIP" -d "$OBLIVION_REMASTERED_CONFIG_DIR"

# Remove temporary zip
rm -f "$TEMP_ZIP"

zenity --info --title="Preset Applied" --text="$preset_choice preset has been successfully applied!" --width=400

# Ask again if user wants to make files immutable
zenity --question --title="Make Files Read-Only" --text="Would you like to make GameUserSettings.ini and Engine.ini read-only (immutable)?\n(Game updates will not break the configuration)"

if [ $? -eq 0 ]; then
    # If user didn't unlock files earlier, request sudo password again
    if [ -z "$SUDO_PASS" ]; then
        while true; do
            SUDO_PASS=$(zenity --password --title="Enter SUDO Password to Lock Files")

            if [ $? -ne 0 ]; then
                zenity --error --title="Cancelled" --text="Operation cancelled by user."
                exit 1
            fi

            echo "$SUDO_PASS" | sudo -S -v 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "Password accepted."
                break
            else
                zenity --error --title="Incorrect Password" --text="Incorrect password. Try again."
            fi
        done
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            echo "$SUDO_PASS" | sudo -S chattr +i "$FILE"
            echo "Set immutable on $FILE"
        fi
    done

    zenity --info --title="Success" --text="Files are now read-only (immutable)!"
fi
