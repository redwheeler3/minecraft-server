# Minecraft Bedrock Server

Utilities for maintaining a Minecraft Bedrock Dedicated Server on Windows.

This repository contains a PowerShell update/startup script and a small Node.js helper that finds the latest Bedrock server download URL from the official Minecraft server download page.

## Repository Contents

| File | Purpose |
| --- | --- |
| `MinecraftBedrockServerUpdateScript.ps1` | Main PowerShell script that checks for Bedrock server updates, backs up configuration files, downloads the latest server ZIP, installs it, restores configuration, and starts the server. |
| `get-bedrock-url.js` | Node.js script that uses Playwright/Chrome to scrape the latest Bedrock Dedicated Server ZIP URL from minecraft.net. |
| `package.json` / `package-lock.json` | Node dependency metadata. The project currently depends on `playwright`. |

## What the Update Script Does

`MinecraftBedrockServerUpdateScript.ps1` is intended to run from the directory above the `bedrock-server` folder. It:

1. Uses `get-bedrock-url.js` to find the latest official Bedrock Dedicated Server ZIP.
2. Checks whether that ZIP has already been downloaded into the backup directory.
3. Backs up important server configuration files:
   - `server.properties`
   - `allowlist.json`, when present
   - `permissions.json`, when present
4. Removes previously downloaded Bedrock server ZIP files from the backup directory.
5. Downloads the latest Bedrock server ZIP.
6. Stops the currently running `bedrock_server` process, if one is running.
7. Extracts the downloaded ZIP into the server directory.
8. Restores the backed-up configuration files.
9. Starts `bedrock_server.exe` if it is not already running.
10. Writes script and server logs to files under the configured root directory.

## Requirements

- Windows
- PowerShell
- Node.js
- npm
- Google Chrome installed, because the Playwright helper launches Chrome with `channel: 'chrome'`
- A `bedrock-server` directory is optional before first run. The update script creates it and extracts the official server ZIP into it when installing for the first time.

## Setup

1. Install Node dependencies:

   ```powershell
   npm install
   ```

2. Review the directory variables near the top of `MinecraftBedrockServerUpdateScript.ps1` and adjust them if needed. By default, `$rootDir` is set to `$PSScriptRoot`, which means “the directory containing this PowerShell script”:

   ```powershell
   $rootDir = $PSScriptRoot
   $gameDir = "$rootDir\bedrock-server"
   $backupDir = "$rootDir\BACKUP"
   $scriptLogFile = "$rootDir\MinecraftScriptLog.log"
   $serverLogFlle = "$rootDir\MinecraftServerLog.log"
   ```

3. Keep `MinecraftBedrockServerUpdateScript.ps1`, `get-bedrock-url.js`, and `package.json` together in the same root folder. If you already have an existing `bedrock-server` folder, place it there too. Otherwise, the script will create `bedrock-server` on first install. The PowerShell script expects the Node helper to be in the same root folder:

   ```powershell
   $nodeScript = "$rootDir\get-bedrock-url.js"
   ```

4. Test the script manually in PowerShell before scheduling it:

   ```powershell
   .\MinecraftBedrockServerUpdateScript.ps1
   ```

5. After confirming it works, create a Windows Task Scheduler task to run it:
   - At startup
   - Periodically when nobody is likely to be connected to the server

## Notes

- The official Bedrock Dedicated Server ZIP includes a default `server.properties` file. On a first-time install, the script allows `server.properties` to be missing and keeps the default file extracted from the ZIP.
- On later updates, if `server.properties`, `allowlist.json`, or `permissions.json` already exist, the script backs them up before extracting the new server files and restores them afterward.
- The script uses downloaded ZIP filenames to determine whether an update has already been downloaded.
- If the download fails, the script attempts to start the existing server if it is not already running.
- Logs are written to the paths configured in `$scriptLogFile` and `$serverLogFlle`.

## Nintendo Switch Connection Instructions

The following instructions were migrated from the previous PDF file, `How to connect to the server on Switch.pdf`.

Source: [Shockbyte - How to Connect to your Minecraft Bedrock Server on Nintendo Switch](https://shockbyte.com/billing/knowledgebase/850/How-to-Connect-to-your-Minecraft-Bedrock-Server-on-Nintendo-Switch.html)

### Configure DNS on the Nintendo Switch

1. Go to the home screen by pressing the house button.
2. Navigate to **System Settings** by selecting the gear icon.
3. Navigate to **Internet** on the left-hand sidebar.
4. Select **Internet Settings**.
5. If you are prompted for a parental control password in the steps below, the code is `0710`.
6. Select your currently connected network under **Registered Networks**. If there is no currently connected network, choose the network you want to connect to under **Networks Found**, enter the correct password, and then go back to step 4.
7. Select **Change Settings**.
8. Locate **DNS Settings** and set it to **Manual**.
9. For **Primary DNS**, use:

   ```text
   104.238.130.180
   ```

10. For **Secondary DNS**, use:

    ```text
    008.008.008.008
    ```

11. Select **Save**.
12. Select **Connect to This Network**.

### Connect from Minecraft

Once inside Minecraft:

1. Select **Play** from the main menu.
2. Go to the **Servers** tab and select any featured server.
3. On the server list, look for **QYA Server**. If you find it, select it. If you do not, continue to the next step.
4. Select **Connect to a Server**.
5. Enter the following server address:

   ```text
   minecraft.jeffo.net
   ```

6. Turn on **Add to Server List**.
7. Select **Submit**.
