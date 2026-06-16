# Triumvirate AutoLogin + Character Move Login UI

A custom no-MPQ login UI for the Triumvirate WoW 3.3.5a client. Adds a Triumvirate logo, Classic background, saved account selection, visual character reordering with Move Up/Down controls, Triumvirate links, Discord button, and small “Made by Scuz” credit. Externalised GlueXML files install directly into Interface with no Data patch files.

Custom login-screen package for the Triumvirate WoW 3.3.5a client.

This build is the no-MPQ / externalised GlueXML version. It does not use a `Data` folder or MPQ patch files. All custom login UI files are loose files under `Interface/`.

## Features

- Custom Triumvirate WoW login logo.
- Fixed Classic (`cl`) login background.
- Saved account selection panel.
- Saved account/password convenience support.
- Character select screen with visual character reordering.
- Move Up / Move Down buttons for changing the displayed character order.
- Character order is saved separately from the account/password data.
- Triumvirate-only server list.
- Manage Account button opens: `https://triumvirate-wow.com/login`
- Community Site button opens: `https://triumvirate-wow.com`
- Discord button opens: `https://discord.gg/efU2QtUuFb`
- Includes small vanity text: `Made by Scuz`
- Removes the old Autologin START / Status panel.
- No MPQ files required.

## Installation

1. Close World of Warcraft completely.

2. Open your Triumvirate WoW client folder. This is the folder that contains `Wow.exe`, `Data`, `Interface`, and `WTF`.

3. Extract the contents of this zip directly into the WoW client folder.

   After extraction, you should have files such as:

   ```text
   Interface/LoginUI.lua
   Interface/GlueXML/AccountLogin.lua
   Interface/GlueXML/AccountLogin.xml
   Interface/GlueXML/CharacterSelect.lua
   Interface/GlueXML/CharacterSelect.xml
   Interface/Glues/Common/Triumvirate-WoW-Login-Logo.tga
   ```

4. Make sure you did not accidentally extract the zip into an extra nested folder.

   Correct:

   ```text
   WoW Folder/Interface/GlueXML/AccountLogin.lua
   ```

   Incorrect:

   ```text
   WoW Folder/Triumvirate-AutoLogin-CharMove-no-MPQ/Interface/GlueXML/AccountLogin.lua
   ```

5. Launch the game.

## Updating from an older build

1. Close WoW.
2. Back up your current `Interface/GlueXML` folder if you want a rollback option.
3. Extract this zip over the client folder and allow files to be replaced.
4. Launch WoW and test the login screen.

## Optional cleanup

This build does not use MPQs. If you previously installed an older MPQ-based version of this login UI, remove these files if they exist:

```text
Data/enGB/patch-enGB-a.MPQ
Data/enUS/patch-enUS-a.MPQ
```

Only remove those exact custom patch files if you know they came from the old login UI package.

## Character reorder notes

The character list reorder feature is visual only. It changes the displayed order on the character select screen, but it does not alter the server's real character order.

To reorder characters:

1. Select a character on the character select screen.
2. Click `Move Up` or `Move Down`.
3. The display order is saved for next time.

If the order ever becomes strange after renaming or deleting characters, simply move the characters again to rebuild the saved order.

## Troubleshooting

### The login screen did not change

The files were probably extracted into the wrong folder. Check that this path exists:

```text
WoW Folder/Interface/GlueXML/AccountLogin.lua
```

### The old logo or background still appears

Close WoW and delete the `Cache` folder from the WoW client directory, then relaunch.

### Account details disappear

Make sure you are using this no-MPQ build and not mixing files from older builds. Extract this package over the client folder again.

### Login says the password is wrong

Check that no old experimental character-order marker is still inside `WTF/Config.wtf` under `SET accountName`.

You can also remove any old manual line like:

```text
SET CharacterOrder "Scuz,Altname,Otheralt"
```

This build does not need that line.

## Notes

This package modifies the WoW GlueXML login UI. It is intended for a Wrath 3.3.5a Triumvirate client setup.

Made by Scuz.
