# Minecraft Bedrock Server

Utilities for running and updating a Minecraft Bedrock Dedicated Server on Windows. After initial setup, schedule the PowerShell script with Windows Task Scheduler to automatically check for the latest official server release, install updates when needed, preserve your world and configuration, and start the server again without user interaction.

## What This Does

This repository contains a small Windows automation setup:

- `MinecraftBedrockServerUpdateScript.ps1` checks for updates, backs up local server state, installs the latest Bedrock server files, restores your world/configuration, and starts `bedrock_server.exe`.
- `get-bedrock-url.js` uses Playwright/Chrome to find the latest official Bedrock Dedicated Server ZIP URL from minecraft.net.
- `package.json` / `package-lock.json` define the Node dependency on `playwright`.

The script resolves paths relative to its own location, so the repository folder is treated as the server root.

## Requirements

- Windows
- PowerShell, included with Windows
- Node.js and npm
- Google Chrome, because the helper script launches Playwright with `channel: 'chrome'`

The `bedrock-server` folder does not need to exist before the first run. The script creates it when installing the server.

## Quick Start

There are two common setup options.

### Option A: Beginner setup without Git

1. Install the required tools:
   - [Node.js](https://nodejs.org/) so the `node` and `npm` commands are available.
   - [Google Chrome](https://www.google.com/chrome/) so the helper script can find the latest Bedrock download.
2. Download this repository from GitHub:
   - Open the repository page in your browser.
   - Select **Code**.
   - Select **Download ZIP**.
3. Extract the ZIP somewhere permanent, for example:

   ```text
   C:\MinecraftServer
   ```

   Avoid temporary folders like `Downloads` if you plan to run the server long term.

4. Open PowerShell in the extracted folder:
   - Open the folder in File Explorer.
   - Right-click empty space in the folder.
   - Select **Open in Terminal** or **Open PowerShell window here**.
5. Install dependencies and run the script:

   ```powershell
   npm install
   .\MinecraftBedrockServerUpdateScript.ps1
   ```

If PowerShell blocks the script, run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\MinecraftBedrockServerUpdateScript.ps1
```

### Option B: Developer setup with Git

```powershell
git clone https://github.com/redwheeler3/minecraft-server.git
cd minecraft-server
npm install
.\MinecraftBedrockServerUpdateScript.ps1
```

On first run, the script downloads the latest official Bedrock Dedicated Server ZIP, creates `bedrock-server/`, extracts the server files, and starts `bedrock_server.exe`.

## How Updates Work

The script uses these paths under the repository/script folder:

```powershell
$rootDir = $PSScriptRoot
$gameDir = "$rootDir\bedrock-server"
$backupDir = "$rootDir\BACKUP"
$scriptLogFile = "$rootDir\MinecraftScriptLog.log"
$serverLogFlle = "$rootDir\MinecraftServerLog.log"
```

During an install or update, the script:

1. Finds the latest official Bedrock Dedicated Server ZIP.
2. Skips the update if that ZIP was already downloaded.
3. Backs up local server state when present:
   - `server.properties`
   - `allowlist.json`
   - `permissions.json`
   - `valid_known_packs.json`
   - `worlds/`
4. Removes older downloaded server ZIPs from `BACKUP/`.
5. Downloads the latest ZIP.
6. Stops any running `bedrock_server` process.
7. Recreates `bedrock-server/` for a clean install.
8. Extracts the ZIP, restores the backed-up state, and starts the server.

Generated runtime files are intentionally ignored by Git:

```text
node_modules/
BACKUP/
*.log
bedrock-server/
```

If you already have an existing `bedrock-server` folder, place it beside `MinecraftBedrockServerUpdateScript.ps1` before running the script.

## Scheduling with Windows Task Scheduler

After manually testing the script, schedule it with Windows Task Scheduler.

Important general settings:

- Select **Run whether user is logged on or not** so the server can start after reboots or while no one is signed in.
- Check **Run with highest privileges** so the script has the permissions it needs to stop/start the server process and update files.

Suggested action:

```text
Program/script: powershell.exe
Arguments: -ExecutionPolicy Bypass -File "C:\path\to\minecraft-server\MinecraftBedrockServerUpdateScript.ps1"
Start in: C:\path\to\minecraft-server
```

Suggested triggers:

- At system startup, so the server starts after a reboot.
- On a recurring schedule at a low-traffic time, so updates are checked when players are less likely to be connected.
- Optionally, when the computer resumes from sleep:
  - Begin the task: **On an event**
  - Log: `System`
  - Source: `Microsoft-Windows-Power-Troubleshooter`
  - Event ID: `1`

The script uses `$PSScriptRoot`, but setting **Start in** is still recommended because it makes scheduled task behavior easier to reason about.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| PowerShell blocks the script | Run it with `powershell.exe -ExecutionPolicy Bypass -File .\MinecraftBedrockServerUpdateScript.ps1`. |
| `node` or `npm` is not found | Install Node.js, then confirm with `node --version` and `npm --version`. |
| Playwright dependencies are missing | Run `npm install` from the repository folder. |
| Chrome is not installed | Install Google Chrome, or update `get-bedrock-url.js` to use a different installed browser/channel. |
| Download URL cannot be found | Microsoft may have changed the Bedrock download page; `get-bedrock-url.js` may need its selector updated. |
| Startup, download, extraction, or update issues | Check `MinecraftScriptLog.log` and `MinecraftServerLog.log`. |

## Nintendo Switch Connection Instructions

Source: [Shockbyte - How to Connect to your Minecraft Bedrock Server on Nintendo Switch](https://shockbyte.com/billing/knowledgebase/850/How-to-Connect-to-your-Minecraft-Bedrock-Server-on-Nintendo-Switch.html)

### Configure DNS on the Nintendo Switch

1. Press the house button to go to the home screen.
2. Open **System Settings**.
3. Select **Internet** from the left sidebar.
4. Select **Internet Settings**.
5. If prompted for a parental control password, the code is `0710`.
6. Select your current network under **Registered Networks**. If no network is connected, choose one under **Networks Found**, enter the password, then return to **Internet Settings**.
7. Select **Change Settings**.
8. Set **DNS Settings** to **Manual**.
9. Set **Primary DNS** to:

   ```text
   104.238.130.180
   ```

10. Set **Secondary DNS** to:

    ```text
    008.008.008.008
    ```

11. Select **Save**.
12. Select **Connect to This Network**.

### Connect from Minecraft

1. Select **Play** from the main menu.
2. Open the **Servers** tab and select any featured server.
3. On the server list, select your saved server name if it appears. Otherwise, continue.
4. Select **Connect to a Server**.
5. Enter your server address, for example:

   ```text
   your-server.example.com
   ```

6. Turn on **Add to Server List**.
7. Select **Submit**.

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.
