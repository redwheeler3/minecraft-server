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

`MinecraftBedrockServerUpdateScript.ps1` uses its own directory as the server root by default. The `bedrock-server` folder, `BACKUP` folder, logs, and helper script are all resolved relative to the PowerShell script location. It:

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
10. Writes script and server logs to files under the script/root directory.

## Requirements

- Windows
- PowerShell
- Node.js
- npm
- Google Chrome installed, because the Playwright helper launches Chrome with `channel: 'chrome'`
- A `bedrock-server` directory is optional before first run. The update script creates it and extracts the official server ZIP into it when installing for the first time.

## Quick Start

From the repository/root folder:

```powershell
npm install
.\MinecraftBedrockServerUpdateScript.ps1
```

On first run, the script downloads the latest official Bedrock Dedicated Server ZIP, creates the server directory, extracts the server files, and starts `bedrock_server.exe`.

## Setup

1. Install Node dependencies:

   ```powershell
   npm install
   ```

2. The script uses `$PSScriptRoot` as `$rootDir`, which means “the directory containing this PowerShell script.” In normal use, you do not need to change this. The related paths are built from that root:

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

## First-Time Install Behavior

The first run can start from only this repository and its Node dependencies. The `bedrock-server` folder does **not** need to exist ahead of time.

On first install, the script:

1. Finds the latest official Bedrock Dedicated Server ZIP URL.
2. Creates `BACKUP/` if needed.
3. Creates `bedrock-server/` if needed.
4. Downloads the server ZIP into `BACKUP/`.
5. Extracts the ZIP into `bedrock-server/`.
6. Keeps the default `server.properties` that is included in the official server ZIP.
7. Starts `bedrock-server\bedrock_server.exe`.

After the first successful run, the generated layout will look roughly like this:

```text
minecraft-server/
├─ MinecraftBedrockServerUpdateScript.ps1
├─ get-bedrock-url.js
├─ package.json
├─ package-lock.json
├─ README.md
├─ BACKUP/
│  └─ bedrock-server-<version>.zip
├─ bedrock-server/
│  ├─ bedrock_server.exe
│  ├─ server.properties
│  ├─ allowlist.json
│  ├─ permissions.json
│  └─ ...
├─ MinecraftScriptLog.log
└─ MinecraftServerLog.log
```

## Configuration Preserved on Updates

When the server is already installed, the script preserves local configuration before extracting updated server files.

The following files are backed up when present and restored after extraction:

- `server.properties`
- `allowlist.json`
- `permissions.json`

If one of these files is missing, the script skips it instead of failing. This allows a clean first-time install where `server.properties` comes from the official ZIP.

## Generated Files

The repository includes a `.gitignore` for generated dependencies, downloads, logs, and server runtime files:

```text
node_modules/
BACKUP/
*.log
bedrock-server/
```

This keeps the Git repository focused on the automation scripts and documentation rather than downloaded server binaries, runtime data, logs, and local worlds.

## Scheduling with Windows Task Scheduler

After manually testing the script, you can schedule it with Windows Task Scheduler.

Suggested action settings:

```text
Program/script: powershell.exe
Arguments: -ExecutionPolicy Bypass -File "C:\path\to\minecraft-server\MinecraftBedrockServerUpdateScript.ps1"
Start in: C:\path\to\minecraft-server
```

Suggested triggers:

- At system startup, so the server starts automatically after a reboot.
- On a recurring schedule at a low-traffic time, so the script can check for updates when players are unlikely to be connected.

`$PSScriptRoot` is used for the root directory, so the script resolves paths relative to the script file itself. Setting **Start in** is still recommended because it makes scheduled task behavior easier to reason about.

## Troubleshooting

### PowerShell blocks the script

If PowerShell blocks local script execution, run it with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\MinecraftBedrockServerUpdateScript.ps1
```

### Node or npm is not found

Install Node.js, then confirm both commands work:

```powershell
node --version
npm --version
```

### Playwright or dependencies are missing

Run:

```powershell
npm install
```

### Chrome is not installed

The Node helper launches Playwright using:

```js
channel: 'chrome'
```

Install Google Chrome, or update `get-bedrock-url.js` to use a different installed browser/channel.

### Download URL cannot be found

The script depends on the structure of the official Minecraft Bedrock server download page. If Microsoft changes that page, `get-bedrock-url.js` may need its selector updated.

### Check the logs

The script writes logs to:

```text
MinecraftScriptLog.log
MinecraftServerLog.log
```

These are the first places to check when troubleshooting startup, download, extraction, or update issues.

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
3. On the server list, look for your saved server name. If you find it, select it. If you do not, continue to the next step.
4. Select **Connect to a Server**.
5. Enter your server address. For example:

   ```text
   your-server.example.com
   ```

6. Turn on **Add to Server List**.
7. Select **Submit**.

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.
