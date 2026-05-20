# MINECRAFT BEDROCK SERVER UPDATE SCRIPT, v1.2 (2/16/2025)

# INSTRUCTIONS:
# MICROSOFT POWERSHELL SCRIPT
# (1) RENAME rootDir TO THE DIRECTORY ABOVE YOUR SERVER DIRECTORY
# (2) PUT THIS SCRIPT FILE IN THAT DIRECTORY WITH .PS1 FILE EXTENSION
# (3) TEST IT IN POWERSHELL, MAKE SURE IT WORKS
# (4) CREATE POWERSHELL TASK IN WINDOWS TASK SCHEDULER TO RUN AT START UP AND PERIODICALLY WHEN NOBODY IS LIKELY TO BE CONNECTED TO SERVER
# (5) ???
# (6) PROFIT

# CREDITS:  u/WhetselS u/Nejireta_ u/rockknocker u/redwheeler
# LINKS: 	https://www.reddit.com/r/PowerShell/comments/xy9xqh/script_for_updating_minecraft_bedrock_server_on/
#			https://www.dvgaming.de/minecraft-pe-bedrock-windows-automatic-update-script/

# DIRECTORIES
$rootDir = $PSScriptRoot
$gameDir = "$rootDir\bedrock-server"
$backupDir = "$rootDir\BACKUP"
$scriptLogFile = "$rootDir\MinecraftScriptLog.log"
$serverLogFlle = "$rootDir\MinecraftServerLog.log"
$serverExe = "$gameDir\bedrock_server.exe"

# LOGGING FUNCTION
function Write-Log {
	Param ([string]$logString)
	$stamp = (Get-Date).toString("[yyyy-MM-dd HH:mm:ss.fff IN\FO]")
	$logMessage = "$stamp $logString"
	Add-content $scriptLogFile -value $logMessage
}

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# GET DOWNLOAD URL USING PLAYWRIGHT
Write-Log "Fetching latest download URL via Playwright..."

$nodeScript = "$rootDir\get-bedrock-url.js"

try {
$nodeOutput = node $nodeScript 2>&1

foreach ($line in $nodeOutput) {
    Write-Log $line
}

# Find the line that contains the URL
$urlLine = $nodeOutput | Where-Object { $_ -match 'https://.*\.zip' } | Select-Object -First 1

if (-not $urlLine) {
    Write-Log "ERROR: Could not find URL line in Node output."
    exit(1)
}

# Extract the URL from that line
$urlMatch = [regex]::Match($urlLine, 'https://[^\s]+\.zip')

if (-not $urlMatch.Success) {
    Write-Log "ERROR: Could not extract URL from Node output."
    exit(1)
}

$url = $urlMatch.Value
}

catch {
    Write-Log "ERROR: Failed to execute Node script."
    exit(1)
}

if (-not $url -or $url -notmatch "bedrockdedicatedserver") {
    Write-Log "ERROR: Invalid download URL returned: $url"
    exit(1)
}

$url = $url.Trim()
$filename = Split-Path $url -Leaf
$output = "$backupDir\$filename"

Write-Log "Latest version detected: $filename"

# CHECK IF FILE ALREADY DOWNLOADED OR SERVER INSTALLED
$downloadExists = Test-Path -Path $output -PathType Leaf
$serverInstalled = Test-Path -Path $serverExe -PathType Leaf

if (!$downloadExists -or !$serverInstalled) { 
	if (!$downloadExists) {
		Write-Log "Update available: $filename."
	}
	else {
		Write-Log "Server executable not found. Installing from existing download: $filename."
	}

	# DO A BACKUP OF CONFIG 
	if (!(Test-Path -Path "$backupDir")) {
		New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
	}

	if (!(Test-Path -Path "$gameDir")) {
		Write-Log "Creating server directory: $gameDir"
		New-Item -Path $gameDir -ItemType Directory -Force | Out-Null
	}
	
	if (Test-Path -Path "$gameDir\server.properties" -PathType Leaf) {
		Write-Log "Backing up: server.properties."
		Copy-Item -Path "$gameDir\server.properties" -Destination $backupDir 
	}
	else {
		Write-Log "No server.properties found to back up. This is expected on first install."
	}
	
	if (Test-Path -Path "$gameDir\allowlist.json" -PathType Leaf) {
		Write-Log "Backing up: allowlist.json."
		Copy-Item -Path "$gameDir\allowlist.json" -Destination $backupDir
	}
	
	if (Test-Path -Path "$gameDir\permissions.json" -PathType Leaf) {
		Write-Log "Backing up: permissions.json."
		Copy-Item -Path "$gameDir\permissions.json" -Destination $backupDir 
	}

	if (!$downloadExists) {
		# DELETE PREVIOUSLY DOWNLOADED SERVER ZIPS
		if (Test-Path -Path "$backupDir\bedrock-server-*.zip" -PathType Leaf) {
			Write-Log "Deleting previously downloaded server .zip files."
			Remove-Item -Path "$backupDir\bedrock-server-*.zip"
		}

		# DOWNLOAD UPDATED SERVER .ZIP FILE
		Write-Log "Downloading: $filename."
		try {
			Invoke-WebRequest -Uri $url -OutFile $output 
		}
		catch {
			# IF ERROR, WE CAN'T UPDATE, SO START THE SERVER IF IT'S NOT ALREADY RUNNING AND EXIT.
			Write-Log "ERROR: Web request to download new server failed."
			$serverProcess = get-process -name bedrock_server -ErrorAction SilentlyContinue
			if (($null -eq $serverProcess) -and (Test-Path -Path $serverExe -PathType Leaf)) {
				Write-Log "Starting server. Update failed, so script exiting with error."
				& $serverExe 2>&1 | Out-File $serverLogFlle -Append -Encoding utf8
			}
			elseif ($null -ne $serverProcess) {
				Write-Log "Server already running. Update failed, so script exiting with error."
			}
			else {
				Write-Log "Server executable not found. Update failed, so script exiting with error."
			}
			exit(1)
		} 
	}

	# STOP SERVER
	if (get-process -name bedrock_server -ErrorAction SilentlyContinue) {
		Write-Log "Stopping server."
		Stop-Process -name "bedrock_server" 
		if (get-process -name bedrock_server -ErrorAction SilentlyContinue) {
			Write-Log "ERROR: Could not stop server."
			if (Test-Path -Path "$backupDir\bedrock-server-*.zip" -PathType Leaf) {
				Write-Log "Deleting previously downloaded server .zip files."
				Remove-Item -Path "$backupDir\bedrock-server-*.zip"
			}
			Write-Log "Exiting with error."
			exit(1)
		}
	}

	# UNZIP
	Write-Log "Updating server files."
	Expand-Archive -LiteralPath $output -DestinationPath $gameDir -Force 

	# RECOVER BACKUP OF CONFIG 
	if (Test-Path -Path "$backupDir\server.properties" -PathType Leaf) {
		Write-Log "Restoring: server.properties."
		Copy-Item -Path "$backupDir\server.properties" -Destination $gameDir 
	}
	else {
		Write-Log "No backed up server.properties to restore. Keeping default from server ZIP."
	}
	
	if (Test-Path -Path "$backupDir\allowlist.json" -PathType Leaf) {
		Write-Log "Restoring: allowlist.json."
		Copy-Item -Path "$backupDir\allowlist.json" -Destination $gameDir 
	}
	
	if (Test-Path -Path "$backupDir\permissions.json" -PathType Leaf) {
		Write-Log "Restoring: permissions.json."
		Copy-Item -Path "$backupDir\permissions.json" -Destination $gameDir 
	}
} 
else {
	Write-Log "No update required. Already using: $filename."
}

# START SERVER
if ($null -eq (get-process -name bedrock_server -ErrorAction SilentlyContinue)) {
	Write-Log "Starting server. Script exiting with success."
	& $serverExe 2>&1 | Out-File $serverLogFlle -Append -Encoding utf8
}
else {
	Write-Log "Server already running. Script exiting with success."
}

exit(0)
