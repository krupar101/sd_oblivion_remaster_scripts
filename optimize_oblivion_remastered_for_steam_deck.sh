#!/bin/bash
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

# Determine where Oblivion Remastered is installed
if [ -d "$SSD_OBLIVION_REMASTERED_COMPAT_DIR" ]; then
    echo "Oblivion Remastered installation found on Internal SSD."
    OBLIVION_REMASTERED_COMPAT_DIR="$SSD_OBLIVION_REMASTERED_COMPAT_DIR"
elif [ -n "$SD_MOUNT" ] && [ -d "$SD_OBLIVION_REMASTERED_COMPAT_DIR" ]; then
    echo "Oblivion Remastered installation found on SD Card."
    OBLIVION_REMASTERED_COMPAT_DIR="$SD_OBLIVION_REMASTERED_COMPAT_DIR"
else
    echo "ERROR: Oblivion Remastered installation not found on Internal SSD or SD Card."
    exit 1
fi

OBLIVION_REMASTERED_CONFIG_DIR="$OBLIVION_REMASTERED_COMPAT_DIR/$FOLDER_SUFFIX"

# Ask user for preset choice
preset_choice=$(zenity --list \
    --title="Oblivion Remastered Preset Selector" \
    --text="Which preset would you like to apply to Oblivion Remastered?" \
    --radiolist \
    --column="Select" --column="Preset" \
    TRUE "Performance" \
    FALSE "Quality" \
    FALSE "Restore Defaults" \
    --width=450 --height=350)

# Check if user canceled
if [ $? -ne 0 ]; then
    echo "Cancel was pressed or the dialog was closed. Exiting."
    exit 1
fi

# Set download URL based on choice
if [ "$preset_choice" == "Performance" ]; then
    ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/performance.zip"
    echo "Performance preset selected."
elif [ "$preset_choice" == "Quality" ]; then
    ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/quality.zip"
    echo "Quality preset selected."
elif [ "$preset_choice" == "Restore Defaults" ]; then
    ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/restore_defaults.zip"
    echo "Restore Defaults selected."
else
    echo "Unknown option selected. Exiting."
    exit 1
fi

echo "$preset_choice selected"

# Make sure the config directory exists
mkdir -p "$OBLIVION_REMASTERED_CONFIG_DIR"

# Download and unzip directly into the config directory
TEMP_ZIP="$OBLIVION_REMASTERED_CONFIG_DIR/preset.zip"

echo "Downloading preset..."
curl -L -o "$TEMP_ZIP" "$ZIP_URL"

echo "Unzipping preset..."
unzip -o "$TEMP_ZIP" -d "$OBLIVION_REMASTERED_CONFIG_DIR"

# Remove the downloaded zip file
rm -f "$TEMP_ZIP"

# Show success message
zenity --info \
    --title="Preset Applied" \
    --text="$preset_choice preset has been successfully applied to Oblivion Remastered!" \
    --width=400

echo "$preset_choice preset applied successfully!"
