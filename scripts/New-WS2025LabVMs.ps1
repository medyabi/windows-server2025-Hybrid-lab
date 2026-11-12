<#
.SYNOPSIS
    Builds a Windows Server 2025 template VHDX from the ISO, then deploys N VMs from it
    and activates them automatically with AVMA (Automatic Virtual Machine Activation).

.DESCRIPTION
    Step 0 - Pre-checks  : admin rights, Hyper-V, host = Datacenter + activated (AVMA requirement)
    Step 1 - Template    : applies install.wim from the ISO to a GPT/UEFI VHDX (already "generalized",
                           no Sysprep needed). Built once, then reused on every run.
    Step 2 - VMs         : per VM -> differencing disk (or full copy) + unattend.xml with
                           computer name, admin password, AVMA key, RDP enabled.
    Step 3 - Verify      : PowerShell Direct into each VM and checks activation status.

    Run on the Hyper-V host in an elevated PowerShell session.

.EXAMPLE
    .\New-WS2025LabVMs.ps1
.EXAMPLE
    .\New-WS2025LabVMs.ps1 -VMPrefix "MTS" -VMCount 8 -InputLocale "fr-FR" -DiskMode Copy
#>

[CmdletBinding()]
param(
    [string]$IsoPath       = "C:\Users\Administrator\Downloads\ISO\en-us_windows_server_2025_updated_oct_2026_x64_dvd_005af0c9.iso",
    [string]$VMRoot        = "C:\Hyper-V\WS2025-Lab",           # Disk 0 (C:) = SSD RAID
    [string]$TemplatePath  = "C:\Hyper-V\Templates\WS2025-DC-Desktop-Template.vhdx",
    [string]$ImageName     = "Windows Server 2025 Datacenter (Desktop Experience)",
    [string]$VMPrefix      = "WS25-VM",
    [int]   $VMCount       = 8,
    [int]   $ProcessorCount = 4,
    [long]  $MemoryStartup = 4GB,
    [long]  $MemoryMin     = 2GB,
    [long]  $MemoryMax     = 8GB,
    [long]  $VhdSize       = 127GB,
    [ValidateSet("Differencing","Copy")]
    [string]$DiskMode      = "Differencing",
    [string]$SwitchName    = "",                                  # empty = first External switch found
    [string]$TimeZone      = "Morocco Standard Time",
    [string]$InputLocale   = "en-US",                             # "fr-FR" for AZERTY keyboard
    [switch]$EnableNested,                                        # nested virt (forces static memory)
    [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"

# AVMA keys - Windows Server 2025 (Microsoft Learn: Automatic Virtual Machine Activation)
$AvmaKeys = @{
    "Datacenter" = "YQB4H-NKHHJ-Q6K4R-4VMY6-VCH67"
    "Standard"   = "WWVGQ-PNHV9-B89P4-8GGM9-9HPQ4"
}

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Gray }

function Get-FreeDriveLetters([int]$Count) {
    $used = @((Get-PSDrive -PSProvider FileSystem).Name) + @((Get-Volume).DriveLetter | Where-Object { $_ })
    $free = [char[]](68..90) | Where-Object { $used -notcontains [string]$_ }   # D..Z
    if ($free.Count -lt $Count) { throw "Not enough free drive letters." }
    return $free | Select-Object -Last $Count
}

function Get-WindowsPartitionLetter([int]$DiskNumber) {
    $basicGuid = '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
    $part = Get-Partition -DiskNumber $DiskNumber | Where-Object { $_.GptType -eq $basicGuid } |
            Sort-Object Size -Descending | Select-Object -First 1
    if (-not $part.DriveLetter -or $part.DriveLetter -eq [char]0) {
        $part | Add-PartitionAccessPath -AssignDriveLetter
        $part = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $part.PartitionNumber
    }
    return $part.DriveLetter
}

# =====================================================================
# STEP 0 - PRE-CHECKS
# =====================================================================
Write-Step "Step 0 - Pre-checks"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script in an elevated PowerShell session."
}
Import-Module Hyper-V
Write-Ok "Running as administrator, Hyper-V module loaded"

# AVMA needs the HOST to be Datacenter edition AND activated
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch "Datacenter") {
    throw "Host is '$($os.Caption)'. AVMA requires a Windows Server Datacenter host."
}
$hostLic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" |
           Where-Object { $_.Name -like "Windows*" } | Select-Object -First 1
if ($hostLic.LicenseStatus -ne 1) {
    throw "Host is not activated (LicenseStatus=$($hostLic.LicenseStatus)). Activate the host first - AVMA guests activate against it."
}
Write-Ok "Host: $($os.Caption) - activated"

if (-not (Test-Path $IsoPath)) { throw "ISO not found: $IsoPath" }
Write-Ok "ISO found"

# Edition -> AVMA key
$edition = if ($ImageName -match "Datacenter") { "Datacenter" } elseif ($ImageName -match "Standard") { "Standard" } else { throw "Cannot detect edition from ImageName '$ImageName'" }
$AvmaKey = $AvmaKeys[$edition]
Write-Ok "Guest edition: $edition -> AVMA key $AvmaKey"

# Virtual switch
if ([string]::IsNullOrWhiteSpace($SwitchName)) {
    $sw = Get-VMSwitch | Where-Object SwitchType -eq "External" | Select-Object -First 1
    if (-not $sw) { throw "No External vSwitch found. Pass -SwitchName <name>." }
    $SwitchName = $sw.Name
} elseif (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    throw "vSwitch '$SwitchName' not found."
}
Write-Ok "vSwitch: $SwitchName"

# VM names + conflicts
$VMNames = 1..$VMCount | ForEach-Object { "{0}{1:D2}" -f $VMPrefix, $_ }
$existing = @(Get-VM -ErrorAction SilentlyContinue | Where-Object { $VMNames -contains $_.Name } | Select-Object -ExpandProperty Name)
if ($existing.Count -gt 0) {
    Write-Info "Already exist - skipping: $($existing -join ', ')"
    $VMNames = @($VMNames | Where-Object { $existing -notcontains $_ })
}
if ($VMNames.Count -eq 0) { Write-Ok "All $VMCount VMs already exist - nothing to do."; return }
Write-Ok "VMs to create: $($VMNames -join ', ')"

# Memory sanity check
$freeRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB
$needRAM = if ($EnableNested) { $MemoryMax * $VMNames.Count } else { $MemoryStartup * $VMNames.Count }
Write-Info ("Host free RAM: {0:N1} GB - needed at boot: {1:N1} GB" -f ($freeRAM/1GB), ($needRAM/1GB))
if ($needRAM -gt $freeRAM) {
    Write-Warning "Not enough free RAM to start all VMs at once. They will be created, but some may fail to start."
}

# Admin password for all VMs
$SecurePwd = Read-Host "Local Administrator password for the VMs" -AsSecureString
$PlainPwd  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePwd))
if ($PlainPwd.Length -lt 8) { throw "Password too short (complexity rules apply)." }

# Avoid "Format disk?" pop-ups while VHDs are mounted
$shellHw = Get-Service ShellHWDetection -ErrorAction SilentlyContinue
if ($shellHw -and $shellHw.Status -eq "Running") { Stop-Service ShellHWDetection -Force }

try {
# =====================================================================
# STEP 1 - TEMPLATE VHDX (built once, reused afterwards)
# =====================================================================
Write-Step "Step 1 - Template VHDX"

if (Test-Path $TemplatePath) {
    Write-Ok "Template already exists - reusing $TemplatePath"
} else {
    New-Item -ItemType Directory -Path (Split-Path $TemplatePath) -Force | Out-Null

    Write-Info "Mounting ISO..."
    $iso = Mount-DiskImage -ImagePath $IsoPath -PassThru
    try {
        $isoLetter = ($iso | Get-Volume).DriveLetter
        $wim = "$($isoLetter):\sources\install.wim"
        if (-not (Test-Path $wim)) { $wim = "$($isoLetter):\sources\install.esd" }

        Write-Info "Editions in the ISO:"
        $images = Get-WindowsImage -ImagePath $wim
        $images | ForEach-Object { Write-Info ("   [{0}] {1}" -f $_.ImageIndex, $_.ImageName) }
        $img = $images | Where-Object ImageName -eq $ImageName | Select-Object -First 1
        if (-not $img) { throw "Image '$ImageName' not found in the ISO. Use one of the names above with -ImageName." }
        Write-Ok "Using index $($img.ImageIndex): $($img.ImageName)"

        Write-Info "Creating dynamic VHDX ($([math]::Round($VhdSize/1GB)) GB)..."
        New-VHD -Path $TemplatePath -SizeBytes $VhdSize -Dynamic | Out-Null
        $disk = Mount-VHD -Path $TemplatePath -Passthru | Get-Disk
        try {
            $letters = Get-FreeDriveLetters 2
            $S = $letters[0]; $W = $letters[1]

            # Standard UEFI/GPT layout (same as Microsoft's WinPE deployment scripts)
            $dp = @"
select disk $($disk.Number)
clean
convert gpt
create partition efi size=260
format quick fs=fat32 label="System"
assign letter=$S
create partition msr size=16
create partition primary
format quick fs=ntfs label="Windows"
assign letter=$W
exit
"@
            $dpFile = Join-Path $env:TEMP "ws25-template-diskpart.txt"
            $dp | Set-Content -Path $dpFile -Encoding ASCII
            diskpart /s $dpFile | Out-Null
            Remove-Item $dpFile -Force
            Write-Ok "Partitioned: EFI=$($S):  Windows=$($W):"

            Write-Info "Applying image (5-10 minutes)..."
            Expand-WindowsImage -ImagePath $wim -Index $img.ImageIndex -ApplyPath "$($W):\" | Out-Null
            Write-Ok "Image applied"

            bcdboot "$($W):\Windows" /s "$($S):" /f UEFI | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "bcdboot failed ($LASTEXITCODE)" }
            Write-Ok "UEFI boot files written"
        } finally {
            Dismount-VHD -Path $TemplatePath
        }
    } finally {
        Dismount-DiskImage -ImagePath $IsoPath | Out-Null
    }

    # Protect the parent disk: a modified parent breaks every differencing child
    Set-ItemProperty -Path $TemplatePath -Name IsReadOnly -Value $true
    Write-Ok "Template ready (read-only): $TemplatePath"
}

# =====================================================================
# STEP 2 - CREATE THE VMs
# =====================================================================
Write-Step "Step 2 - Creating $($VMNames.Count) VMs ($DiskMode disks)"

foreach ($name in $VMNames) {
    Write-Host "`n--- $name ---" -ForegroundColor Yellow
    $vmDir  = Join-Path $VMRoot $name
    $vhdDir = Join-Path $vmDir "Virtual Hard Disks"
    $vhd    = Join-Path $vhdDir "$name-OS.vhdx"
    New-Item -ItemType Directory -Path $vhdDir -Force | Out-Null

    # 2a. OS disk from the template
    if ($DiskMode -eq "Differencing") {
        New-VHD -Path $vhd -ParentPath $TemplatePath -Differencing | Out-Null
    } else {
        Copy-Item -Path $TemplatePath -Destination $vhd
        Set-ItemProperty -Path $vhd -Name IsReadOnly -Value $false
    }
    Write-Ok "OS disk: $vhd"

    # 2b. Inject unattend.xml (name, password, AVMA key, RDP, locale)
    $unattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <ComputerName>$name</ComputerName>
      <ProductKey>$AvmaKey</ProductKey>
      <TimeZone>$TimeZone</TimeZone>
      <RegisteredOwner>Lab</RegisteredOwner>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>
    <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserAuthentication>1</UserAuthentication>
    </component>
    <component name="Microsoft-Windows-Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <FirewallGroups>
        <FirewallGroup wcm:action="add" wcm:keyValue="RemoteDesktop">
          <Active>true</Active>
          <Group>Remote Desktop</Group>
          <Profile>all</Profile>
        </FirewallGroup>
      </FirewallGroups>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>$InputLocale</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserAccounts>
        <AdministratorPassword>
          <Value>$([System.Security.SecurityElement]::Escape($PlainPwd))</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
    </component>
  </settings>
</unattend>
"@

    $disk = Mount-VHD -Path $vhd -Passthru | Get-Disk
    try {
        $W = Get-WindowsPartitionLetter $disk.Number
        $panther = "$($W):\Windows\Panther"
        New-Item -ItemType Directory -Path $panther -Force | Out-Null
        $unattend | Set-Content -Path "$panther\unattend.xml" -Encoding UTF8

        # Remove the answer file (it contains the password) once setup finishes
        $scripts = "$($W):\Windows\Setup\Scripts"
        New-Item -ItemType Directory -Path $scripts -Force | Out-Null
        "@echo off`r`ndel /q /f %WINDIR%\Panther\unattend.xml`r`n" |
            Set-Content -Path "$scripts\SetupComplete.cmd" -Encoding ASCII
        Write-Ok "unattend.xml injected (name=$name, AVMA key, RDP on)"
    } finally {
        Dismount-VHD -Path $vhd
    }

    # 2c. Create the VM (Gen 2, Secure Boot, vTPM)
    New-VM -Name $name -Generation 2 -MemoryStartupBytes $MemoryStartup `
           -VHDPath $vhd -SwitchName $SwitchName -Path $VMRoot | Out-Null

    Set-VM -Name $name -ProcessorCount $ProcessorCount `
           -AutomaticCheckpointsEnabled $false `
           -AutomaticStartAction Start -AutomaticStopAction ShutDown

    if ($EnableNested) {
        # Nested virtualization requires static memory + MAC spoofing for nested VM networking
        Set-VM -Name $name -StaticMemory -MemoryStartupBytes $MemoryMax
        Set-VMProcessor -VMName $name -ExposeVirtualizationExtensions $true
        Get-VMNetworkAdapter -VMName $name | Set-VMNetworkAdapter -MacAddressSpoofing On
    } else {
        Set-VM -Name $name -DynamicMemory -MemoryMinimumBytes $MemoryMin -MemoryMaximumBytes $MemoryMax
    }

    Set-VMFirmware -VMName $name -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows"
    Set-VMKeyProtector -VMName $name -NewLocalKeyProtector
    Enable-VMTPM -VMName $name

    # AVMA REQUIREMENT: Data Exchange (Key-Value Pair Exchange) integration service
    Get-VMIntegrationService -VMName $name |
        Where-Object { $_.Name -eq "Key-Value Pair Exchange" } | Enable-VMIntegrationService
    Enable-VMIntegrationService -VMName $name -Name "Guest Service Interface"

    Start-VM -Name $name
    Write-Ok "$name created and started"
}

} finally {
    if ($shellHw -and $shellHw.Status -eq "Running") { Start-Service ShellHWDetection }
}

# =====================================================================
# STEP 3 - VERIFY ACTIVATION (PowerShell Direct)
# =====================================================================
if ($SkipVerify) { Write-Host "`nVerification skipped." ; return }

Write-Step "Step 3 - Waiting for setup to finish and checking AVMA activation"
Write-Info "First boot (specialize + OOBE + reboot) takes ~3-6 minutes per VM..."

$cred = New-Object System.Management.Automation.PSCredential("Administrator", $SecurePwd)
$results = foreach ($name in $VMNames) {
    $status = "Timeout"; $hostName = ""
    $deadline = (Get-Date).AddMinutes(20)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-Command -VMName $name -Credential $cred -ErrorAction Stop -ScriptBlock {
                $p = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" |
                     Where-Object { $_.Name -like "Windows*" } | Select-Object -First 1
                [pscustomobject]@{ Host = $env:COMPUTERNAME; Status = $p.LicenseStatus; Key = $p.PartialProductKey }
            }
            $hostName = $r.Host
            if ($r.Status -eq 1) { $status = "Licensed (AVMA, key ...$($r.Key))"; break }
            # Guest is up but not yet activated - nudge it
            Invoke-Command -VMName $name -Credential $cred -ScriptBlock { cscript //nologo $env:windir\system32\slmgr.vbs /ato | Out-Null } -ErrorAction SilentlyContinue
            $status = "Not activated yet (status $($r.Status))"
        } catch { }
        Start-Sleep -Seconds 30
    }
    [pscustomobject]@{ VM = $name; ComputerName = $hostName; Activation = $status }
}

$results | Format-Table -AutoSize
Write-Host "Host-side AVMA log: Event Viewer > Application > Event ID 12310 (guest side: 12309)." -ForegroundColor Gray
