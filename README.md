# Ripperdoc Trauma Care

Ripperdocs can treat [Dark Future](https://www.nexusmods.com/cyberpunk2077/mods/16300)'s Injury condition.

In Dark Future, Injury builds up as you take damage and only a Trauma Kit brings it down. With this mod, when V is injured, the ripperdoc screen shows a **Treat injuries** button with the price. Confirm, pay, and every Injury level is cleared, along with the progress toward the next one.

Treatment goes through Dark Future's own cure path, the one its Trauma Kit uses, so Dark Future's status effects, HUD and notifications update the way they do after a kit.

## Price

- **Price per Injury level** (default €$2,000). Progress toward the next level is charged pro rata, so Injury 2 at 40% toward 3 costs 2.4 levels.
- **Minimum fee** (default €$500).
- **Street Cred discount** (default up to 30%): scales from nothing at Street Cred 1 to the full discount at 50.

All three, plus an on/off switch, are on the mod's Mod Settings page.

## Requirements

- [Codeware](https://www.nexusmods.com/cyberpunk2077/mods/7780) (button and confirmation popup)
- [Dark Future](https://www.nexusmods.com/cyberpunk2077/mods/16300) (without it the mod does nothing; it still compiles, so it won't break your scripts)
- [Mod Settings](https://www.nexusmods.com/cyberpunk2077/mods/4885) (optional, for the settings)

## Install

Copy `r6` into the game folder, or install the archive with MO2 or Vortex.

## Compatibility

- It adds one button to the ripperdoc screen and wraps `RipperDocGameController.OnInitialize`. It doesn't replace any game function.
- The button sits above the bottom-right corner, left of where cyberware loadout mods tend to put theirs.

## License

[MIT](LICENSE).
