#!/bin/bash

# Colors for echo
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Password variable
SUDO_PASS=""

# Functions
ask_for_sudo_password() {
    if [ -n "$SUDO_PASS" ]; then
        # Password already provided and valid
        return
    fi

    while true; do
        SUDO_PASS=$(zenity --password --title="Enter SUDO Password")

        if [ $? -ne 0 ]; then
            zenity --error --title="Cancelled" --text="Password entry cancelled. Exiting."
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
}

ensure_sudo_password_is_set() {
    local PASS_STATUS
    PASS_STATUS=$(passwd -S "$USER" 2>/dev/null)
    local STATUS
    STATUS=$(echo "$PASS_STATUS" | awk '{print $2}')

    if [[ "$STATUS" == "NP" ]]; then
        zenity --info --title="No Password Set" --text="No sudo password is set.\nYou must set one now to continue."

        while true; do
            NEW_PASS1=$(zenity --password --title="Set New SUDO Password")
            if [ $? -ne 0 ]; then
                zenity --error --title="Cancelled" --text="Cancelled setting password. Exiting."
                exit 1
            fi

            NEW_PASS2=$(zenity --password --title="Confirm New SUDO Password")
            if [ $? -ne 0 ]; then
                zenity --error --title="Cancelled" --text="Cancelled setting password. Exiting."
                exit 1
            fi

            if [ "$NEW_PASS1" != "$NEW_PASS2" ]; then
                zenity --error --title="Mismatch" --text="Passwords do not match. Try again."
                continue
            fi

            # Use the already entered sudo password to set a new user password
            echo -e "$NEW_PASS1\n$NEW_PASS1" | echo "$SUDO_PASS" | sudo -S passwd "$USER"
            if [ $? -eq 0 ]; then
                zenity --info --title="Password Set" --text="Sudo password successfully set."
                SUDO_PASS="$NEW_PASS1"  # Update SUDO_PASS with the newly set password
                break
            else
                zenity --error --title="Error" --text="Failed to set password. Try again."
            fi
        done
    fi
}

run_sudo() {
    # Helper function to run sudo commands using stored password
    echo "$SUDO_PASS" | sudo -S "$@"
}

# Banner
echo "---------------------"
echo ""
echo -e "${GREEN}Oblivion Remastered optimization script for Steam Deck by krupar${NC}"
echo ""
echo "---------------------"
sleep 1
echo "---------------------"
echo ""
echo "Buy me a coffee @ https://ko-fi.com/krupar"
echo ""
echo "---------------------"
sleep 1

# Paths
SSD_OBLIVION_REMASTERED_COMPAT_DIR="$HOME/.steam/steam/steamapps/compatdata/2623190"
FOLDER_SUFFIX="pfx/drive_c/users/steamuser/Documents/My Games/Oblivion Remastered/Saved/Config/Windows"

SD_MOUNT=$(findmnt -rn -o TARGET | grep '/run/media' | sed 's/\\x20/ /g')

if [ -n "$SD_MOUNT" ]; then
    echo "SD Card is mounted at: $SD_MOUNT"
    SD_OBLIVION_REMASTERED_COMPAT_DIR="$SD_MOUNT/steamapps/compatdata/2623190"
fi

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

# Check if files are immutable
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

# If immutable files detected
if $files_immutable; then
    zenity --info --title="Files are Immutable" --text="Some config files are read-only.\nYou must unlock them to update the preset."

    ask_for_sudo_password
    ensure_sudo_password_is_set

    # Remove immutable
    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            run_sudo chattr -i "$FILE"
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

# Create config dir
mkdir -p "$OBLIVION_REMASTERED_CONFIG_DIR"

# Download and extract preset
TEMP_ZIP="$OBLIVION_REMASTERED_CONFIG_DIR/preset.zip"

echo "Downloading preset..."
curl -L -o "$TEMP_ZIP" "$ZIP_URL"

echo "Unzipping preset..."
unzip -o "$TEMP_ZIP" -d "$OBLIVION_REMASTERED_CONFIG_DIR"

rm -f "$TEMP_ZIP"

zenity --info --title="Preset Applied" --text="$preset_choice preset has been successfully applied!" --width=400

# Ask to make files immutable again
zenity --question --title="Make Files Read-Only" --text="Would you like to make GameUserSettings.ini and Engine.ini read-only (immutable)?"

if [ $? -eq 0 ]; then
    # Use stored password
    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            run_sudo chattr +i "$FILE"
            echo "Set immutable on $FILE"
        fi
    done

    zenity --info --title="Success" --text="Files are now read-only (immutable)!"
fi
