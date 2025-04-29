# The Elder Scrolls IV: Oblivion Remastered - Steam Deck Optimization Script

<p align="center">
  <img src="https://github.com/krupar101/sd_oblivion_remaster_scripts/blob/main/oblivion-remastered.gif" alt="Folondeck" />
</p>

This project provides a quick and easy way to optimize *The Elder Scrolls IV: Oblivion Remastered* for the Steam Deck.  
It applies performance tweaks, disables unnecessary features, and sets optimized game settings for the best experience.

## How to run it?

To run the Steam Deck optimization script for Oblivion Remastered:

1. Run the game at least once up until the main menu after installation.
2. Go to Steam Deck Desktop Mode.
3. Open the **Konsole** application (terminal).
4. Copy and paste the command below into the Konsole and press Enter:

```bash
bash <(curl -s https://raw.githubusercontent.com/krupar101/sd_oblivion_remaster_scripts/refs/heads/main/optimize_oblivion_remastered_for_steam_deck.sh)
```

### Alternatively: Use the .desktop file

You can download this `.desktop` file and run it without needing the Konsole:

[Download Optimize-Oblivion.desktop](https://raw.githubusercontent.com/krupar101/sd_oblivion_remaster_scripts/refs/heads/main/Optimize-Oblivion.desktop)

**Instructions:**
- Right-click the link above → **Save Link As** → Save it anywhere you like but make sure it ends with `.desktop`.
- Right-click the saved file → **Properties** → **Permissions** → Check **"Is executable"**.
- Then double-click the file to run it.

> ## 📢 Important
> 
> **After applying the optimization (via either method), you can return to Gaming Mode and launch the game.**
> 
> **You only need to do this once — unless a future game update overwrites your settings.**

## What does it do?

- Applies the optimized `Engine.ini` by [P40L0X](https://www.nexusmods.com/oblivionremastered/mods/35)
- Disables Lumen as per [Lumen Begone mod by HerrTiSo](https://www.nexusmods.com/oblivionremastered/mods/183)
- Applies an optimized `GameUserSettings.ini` (created by me)

## Quality Preset - Screenshots

| | |
|:--:|:--:|
| ![20250428231059_1](https://github.com/user-attachments/assets/82b3cb87-800b-4c9d-beff-1bb77d388fa6) | ![20250428231122_1](https://github.com/user-attachments/assets/05957519-a443-4d99-8ccb-7edc27fa5b7a) |
| ![20250428231205_1](https://github.com/user-attachments/assets/c6118f43-b1a6-4f08-9061-44076fdf8f1c) | ![20250428231236_1](https://github.com/user-attachments/assets/43a953b3-cabd-4835-83a0-bed26513f06f) |
| ![20250428231256_1](https://github.com/user-attachments/assets/ec1573ab-c7cf-47b0-aeab-086ec8e92179) | ![20250428231313_1](https://github.com/user-attachments/assets/cf72b294-0b54-4539-b62e-f76f20fdfade) |
| ![20250428231527_1](https://github.com/user-attachments/assets/9a16d685-f89e-47ef-9ed7-9b5390f35d31) | |

## Performance Preset - Screenshots

| | |
|:--:|:--:|
| ![20250428230538_1](https://github.com/user-attachments/assets/6b38a35c-fa87-4584-acf8-61075a37373e) | ![20250428230558_1](https://github.com/user-attachments/assets/1588f2d4-1049-491d-81da-f34e18c70973) |
| ![20250428230645_1](https://github.com/user-attachments/assets/e2804006-3ea4-4aa5-bcdf-8ac10d7d42b0) | ![20250428230739_1](https://github.com/user-attachments/assets/c94bec9f-1314-4a1b-936c-dc0bf8186eef) |
| ![20250428230810_1](https://github.com/user-attachments/assets/0c46b778-41d9-4c51-911d-5db47cb0d8c6) | ![20250428230825_1](https://github.com/user-attachments/assets/119cf86d-a038-48e6-941f-554187015c83) |
| ![20250428230858_1](https://github.com/user-attachments/assets/dfa204d7-3369-4ca6-93f9-3a187529b2cf) | |

## Disclaimer

This optimization script is provided as-is.  
Always back up your original configuration files before applying any changes.
