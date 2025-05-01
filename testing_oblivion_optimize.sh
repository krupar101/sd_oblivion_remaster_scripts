#!/bin/bash

echo "RES"

# Colors for echo
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
SUDO_PASS=""

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

function ask_sudo_password() {
    while true; do
        SUDO_PASS=$(zenity --password --title="Enter your SUDO password")

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

function password_set() {
    PASS_STATUS=$(passwd -S "$USER" 2>/dev/null)
    STATUS=$(echo "$PASS_STATUS" | awk '{print $2}')
    if [[ "$STATUS" == "NP" ]]; then
        return 1
    else
        return 0
    fi
}

function ensure_sudo_password_set() {
    while true; do
        password_set
        if [ $? -ne 0 ]; then
            zenity --info --title="No Password Set" --text="You don't have a sudo password set.\nPlease set one now."

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
                zenity --error --title="Passwords Do Not Match" --text="Passwords do not match. Try again."
                continue
            fi

            echo -e "$NEW_PASS1\n$NEW_PASS1" | passwd "$USER"
            if [ $? -ne 0 ]; then
                zenity --error --title="Failed" --text="Failed to set password. Try again."
                continue
            fi

            SUDO_PASS="$NEW_PASS1"
        fi

        if [ -z "$SUDO_PASS" ]; then
            ask_sudo_password
        else
            echo "$SUDO_PASS" | sudo -S -v 2>/dev/null
            if [ $? -ne 0 ]; then
                ask_sudo_password
            fi
        fi

        break
    done
}

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

if $files_immutable; then
    zenity --info --title="Files are Immutable" --text="Some config files are read-only.\nYou must unlock them to update the preset.\n\nYou will be asked for your sudo password."

    ensure_sudo_password_set

    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            echo "$SUDO_PASS" | sudo -S chattr -i "$FILE"
            echo "Removed immutable from $FILE"
        fi
    done
fi

for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        chmod 644 "$FILE"
        echo "Removed red-only from $FILE"
    fi
done

preset_choice=$(zenity --list \
    --title="Oblivion Remastered Preset Selector" \
    --text="Which preset would you like to apply?" \
    --radiolist \
    --column="Select" --column="Preset" \
    TRUE "Quality" \
    FALSE "Overkill" \
    FALSE "Performance" \
    FALSE "Krupar" \
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
    "Overkill")
        ZIP_URL="https://github.com/krupar101/sd_oblivion_remaster_scripts/raw/refs/heads/main/quality.zip"
        ;;
    "Krupar")
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

mkdir -p "$OBLIVION_REMASTERED_CONFIG_DIR"

TEMP_ZIP="$OBLIVION_REMASTERED_CONFIG_DIR/preset.zip"

echo "Downloading preset..."
curl -L -o "$TEMP_ZIP" "$ZIP_URL"

echo "Unzipping preset..."
unzip -o "$TEMP_ZIP" -d "$OBLIVION_REMASTERED_CONFIG_DIR"

rm -f "$TEMP_ZIP"

# ── Patch Save_Settings.sav ────────────────────────────────────────
SAVE_FILE="$OBLIVION_REMASTERED_COMPAT_DIR/pfx/drive_c/users/steamuser/Documents/My Games/Oblivion Remastered/Saved/SaveGames/Save_Settings.sav"

if [[ ("$preset_choice" == "Performance" || "$preset_choice" == "Quality" || "$preset_choice" == "Overkill" || "$preset_choice" == "Krupar") && -f "$SAVE_FILE" ]]; then
    echo "Patching Save_Settings.sav with $preset_choice preset..."

    python3 - <<EOF
from pathlib import Path

# Preset values (key: binary value)
presets = {
    "Performance": {
        "Altar.GraphicsOptions.AntiAliasingMode":         b'4',
        "Altar.GraphicsOptions.AutoSetBestGraphicsOptions": b'0',
        "Altar.GraphicsOptions.Brightness":               b'0.00',
        "Altar.GraphicsOptions.ClothQuality":             b'4',
        "Altar.GraphicsOptions.EffectsQuality":           b'0',
        "Altar.GraphicsOptions.EnableHardwareRaytracing": b'0',
        "Altar.GraphicsOptions.FoliageQuality":           b'4',
        "Altar.GraphicsOptions.GlobalIlluminationQuality": b'4',
        "Altar.GraphicsOptions.HardwareRaytracingMode":   b'0',
        "Altar.GraphicsOptions.Monitor":                  b"'",
        "Altar.GraphicsOptions.PostProcessQuality":       b'4',
        "Altar.GraphicsOptions.ReflectionQuality":        b'4',
        "Altar.GraphicsOptions.ScreenPercentage":         b'50.00',
        "Altar.GraphicsOptions.ScreenSpaceReflection":    b'1',
        "Altar.GraphicsOptions.ShadingQuality":           b'4',
        "Altar.GraphicsOptions.ShadowQuality":            b'4',
        "Altar.GraphicsOptions.ShowFPS":                  b'0',
        "Altar.GraphicsOptions.ShowVRAM":                 b'0',
        "Altar.GraphicsOptions.SoftwareRaytracingQuality": b'0',
        "Altar.GraphicsOptions.TextureQuality":           b'0',
        "Altar.GraphicsOptions.ViewDistanceQuality":      b'1',
        "Altar.GraphicsOptions.VSync":                    b'0',
        "Altar.GraphicsOptions.WindowMode": b'2',
        "r.SetRes": b'1280x800',
        "Altar.UpscalingMethod":                          b'3',
        "Altar.XeSS.Quality":                             b'1'
    },
    "Quality": {
        "Altar.GraphicsOptions.AntiAliasingMode":         b'4',
        "Altar.GraphicsOptions.AutoSetBestGraphicsOptions": b'0',
        "Altar.GraphicsOptions.Brightness":               b'0.00',
        "Altar.GraphicsOptions.ClothQuality":             b'4',
        "Altar.GraphicsOptions.EffectsQuality":           b'0',
        "Altar.GraphicsOptions.EnableHardwareRaytracing": b'0',
        "Altar.GraphicsOptions.FoliageQuality":           b'4',
        "Altar.GraphicsOptions.GlobalIlluminationQuality": b'4',
        "Altar.GraphicsOptions.HardwareRaytracingMode":   b'0',
        "Altar.GraphicsOptions.Monitor":                  b"'",
        "Altar.GraphicsOptions.PostProcessQuality":       b'4',
        "Altar.GraphicsOptions.ReflectionQuality":        b'4',
        "Altar.GraphicsOptions.ScreenPercentage":         b'50.00',
        "Altar.GraphicsOptions.ScreenSpaceReflection":    b'1',
        "Altar.GraphicsOptions.ShadingQuality":           b'4',
        "Altar.GraphicsOptions.ShadowQuality":            b'4',
        "Altar.GraphicsOptions.ShowFPS":                  b'0',
        "Altar.GraphicsOptions.ShowVRAM":                 b'0',
        "Altar.GraphicsOptions.SoftwareRaytracingQuality": b'0',
        "Altar.GraphicsOptions.TextureQuality":           b'1',
        "Altar.GraphicsOptions.ViewDistanceQuality":      b'1',
        "Altar.GraphicsOptions.VSync":                    b'0',
        "Altar.GraphicsOptions.WindowMode": b'2',
        "r.SetRes": b'1280x800',
        "Altar.UpscalingMethod":                          b'3',
        "Altar.XeSS.Quality":                             b'1'
    },
    "Overkill": {
        "Altar.GraphicsOptions.AntiAliasingMode":         b'4',
        "Altar.GraphicsOptions.AutoSetBestGraphicsOptions": b'0',
        "Altar.GraphicsOptions.Brightness":               b'0.00',
        "Altar.GraphicsOptions.ClothQuality":             b'0',
        "Altar.GraphicsOptions.EffectsQuality":           b'0',
        "Altar.GraphicsOptions.EnableHardwareRaytracing": b'0',
        "Altar.GraphicsOptions.FoliageQuality":           b'1',
        "Altar.GraphicsOptions.GlobalIlluminationQuality": b'1',
        "Altar.GraphicsOptions.HardwareRaytracingMode":   b'0',
        "Altar.GraphicsOptions.Monitor":                  b"'",
        "Altar.GraphicsOptions.PostProcessQuality":       b'1',
        "Altar.GraphicsOptions.ReflectionQuality":        b'1',
        "Altar.GraphicsOptions.ScreenPercentage":         b'50.00',
        "Altar.GraphicsOptions.ScreenSpaceReflection":    b'1',
        "Altar.GraphicsOptions.ShadingQuality":           b'0',
        "Altar.GraphicsOptions.ShadowQuality":            b'1',
        "Altar.GraphicsOptions.ShowFPS":                  b'0',
        "Altar.GraphicsOptions.ShowVRAM":                 b'0',
        "Altar.GraphicsOptions.SoftwareRaytracingQuality": b'0',
        "Altar.GraphicsOptions.TextureQuality":           b'1',
        "Altar.GraphicsOptions.ViewDistanceQuality":      b'1',
        "Altar.GraphicsOptions.VSync":                    b'0',
        "Altar.GraphicsOptions.WindowMode": b'2',
        "r.SetRes": b'1280x800',
        "Altar.UpscalingMethod":                          b'3',
        "Altar.XeSS.Quality":                             b'3'
    },
    "Krupar": {
        "Altar.GraphicsOptions.AntiAliasingMode":         b'4',
        "Altar.GraphicsOptions.AutoSetBestGraphicsOptions": b'0',
        "Altar.GraphicsOptions.Brightness":               b'0.00',
        "Altar.GraphicsOptions.ClothQuality":             b'1',
        "Altar.GraphicsOptions.EffectsQuality":           b'2',
        "Altar.GraphicsOptions.EnableHardwareRaytracing": b'0',
        "Altar.GraphicsOptions.FoliageQuality":           b'1',
        "Altar.GraphicsOptions.GlobalIlluminationQuality": b'1',
        "Altar.GraphicsOptions.HardwareRaytracingMode":   b'0',
        "Altar.GraphicsOptions.Monitor":                  b"'",
        "Altar.GraphicsOptions.PostProcessQuality":       b'2',
        "Altar.GraphicsOptions.ReflectionQuality":        b'2',
        "Altar.GraphicsOptions.ScreenPercentage":         b'50.00',
        "Altar.GraphicsOptions.ScreenSpaceReflection":    b'1',
        "Altar.GraphicsOptions.ShadingQuality":           b'1',
        "Altar.GraphicsOptions.ShadowQuality":            b'2',
        "Altar.GraphicsOptions.ShowFPS":                  b'0',
        "Altar.GraphicsOptions.ShowVRAM":                 b'0',
        "Altar.GraphicsOptions.SoftwareRaytracingQuality": b'0',
        "Altar.GraphicsOptions.TextureQuality":           b'2',
        "Altar.GraphicsOptions.ViewDistanceQuality":      b'1',
        "Altar.GraphicsOptions.VSync":                    b'1',
        "Altar.GraphicsOptions.WindowMode": b'2',
        "r.SetRes": b'1280x800',
        "Altar.UpscalingMethod":                          b'3',
        "Altar.XeSS.Quality":                             b'1'
    }
}

target_path = Path("$SAVE_FILE")
target_data = bytearray(target_path.read_bytes())
preset_values = presets.get("$preset_choice")

def find_all_keys(data):
    keys = {}
    i = 0
    while i < len(data):
        if data[i:i+6] == b'Altar.' or data[i:i+8] == b'r.SetRes':
            end = data.find(b'\x00', i)
            if end == -1:
                break
            key = data[i:end].decode('utf-8', errors='ignore')
            val_start = end + 5
            val_end = data.find(b'\x00', val_start)
            value = data[val_start:val_end]
            keys[key] = (i, end, val_start, val_end, value)
            i = val_end + 1
        else:
            i += 1
    return keys


target_keys = find_all_keys(target_data)
patched = 0
for key, new_val in preset_values.items():
    if key in target_keys:
        _, _, val_start, val_end, old_val = target_keys[key]
        replacement = new_val[:len(old_val)].ljust(len(old_val), b'\x00')
        target_data[val_start:val_end] = replacement[:val_end - val_start]
        patched += 1

target_path.write_bytes(target_data)
print(f"✅ Patched $SAVE_FILE using '$preset_choice' preset. Total settings applied: {patched}")
EOF

else
    echo "Skipping save patch: either no Save_Settings.sav found or preset is Restore Defaults."
fi

zenity --info --title="Preset Applied" --text="$preset_choice preset has been successfully applied!" --width=400

for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        chmod 444 "$FILE"
        echo "Set read only on $FILE"
    fi
done
