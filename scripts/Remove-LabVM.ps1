<#
.SYNOPSIS
    Deletes one or more Hyper-V VMs and every file that belongs to them:
    VHDX/AVHDX disks (incl. checkpoints), configuration, and the VM folder.

.DESCRIPTION
    Safety rules:
      - The template VHDX is never deleted.
      - A disk used by any OTHER VM (e.g. a shared differencing parent) is never deleted.
      - When walking a differencing chain, only disks located inside the VM's own folder
        are deleted - parents outside it (like the template) are left alone.
      - The VM folder is only deleted if its name matches the VM name.
    You are asked to confirm each VM. Use -WhatIf for a dry run, -Confirm:$false to skip prompts.

.EXAMPLE
    .\Remove-LabVM.ps1 -Name WS25-VM03
.EXAMPLE
    .\Remove-LabVM.ps1 -Name WS25-VM01,WS25-VM02 -WhatIf
.EXAMPLE
    .\Remove-LabVM.ps1 -Name "WS25-VM*" -Confirm:$false
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,                                                     # wildcards allowed
    [string]$TemplatePath = "C:\Hyper-V\Templates\WS2025-DC-Desktop-Template.vhdx"
)

$ErrorActionPreference = "Stop"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script in an elevated PowerShell session."
}
Import-Module Hyper-V

function Get-VhdChain([string]$Path) {
    $chain = @()
    $p = $Path
    while ($p) {
        $chain += $p
        try { $p = (Get-VHD -Path $p -ErrorAction Stop).ParentPath } catch { $p = $null }
    }
    return $chain
}

function Get-VMDiskPaths($VM) {
    $paths  = @(Get-VMHardDiskDrive -VM $VM | Select-Object -ExpandProperty Path)
    $paths += @(Get-VMSnapshot -VM $VM -ErrorAction SilentlyContinue |
                Get-VMHardDiskDrive | Select-Object -ExpandProperty Path)
    return $paths | Where-Object { $_ } | Sort-Object -Unique
}

function Test-IsUnder([string]$Path, [string]$Folder) {
    if (-not $Folder) { return $false }
    $f = [IO.Path]::GetFullPath($Folder).TrimEnd('\') + '\'
    return [IO.Path]::GetFullPath($Path).StartsWith($f, [StringComparison]::OrdinalIgnoreCase)
}

# ---- Resolve target VMs (wildcards supported) ----
$targets = @(foreach ($n in $Name) { Get-VM -Name $n -ErrorAction SilentlyContinue }) |
           Sort-Object Id -Unique
if (-not $targets) { Write-Warning "No VM matches: $($Name -join ', ')"; return }

# ---- Protected files: template + every disk (and parent) used by other VMs ----
$protected = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
if ($TemplatePath) { [void]$protected.Add([IO.Path]::GetFullPath($TemplatePath)) }
$others = Get-VM | Where-Object { $targets.Id -notcontains $_.Id }
foreach ($o in $others) {
    foreach ($d in Get-VMDiskPaths $o) {
        foreach ($c in Get-VhdChain $d) { [void]$protected.Add([IO.Path]::GetFullPath($c)) }
    }
}

$summary = foreach ($vm in $targets) {
    $vmName   = $vm.Name
    $vmFolder = $vm.Path            # e.g. C:\Hyper-V\WS2025-Lab\WS25-VM03

    # ---- Build the list of disks to delete ----
    $files = @()
    foreach ($d in Get-VMDiskPaths $vm) {
        $chain = Get-VhdChain $d
        for ($i = 0; $i -lt $chain.Count; $i++) {
            $f = [IO.Path]::GetFullPath($chain[$i])
            if ($protected.Contains($f)) { break }                              # template / shared parent
            if ($i -gt 0 -and -not (Test-IsUnder $f $vmFolder)) { break }      # parent outside VM folder
            $files += $f
        }
    }
    $files = $files | Sort-Object -Unique

    # VM folder is only removed if it is clearly dedicated to this VM
    $folderToDelete = $null
    if ($vmFolder -and (Split-Path $vmFolder -Leaf) -eq $vmName -and (Test-Path $vmFolder)) {
        $folderToDelete = $vmFolder
    }

    Write-Host "`n=== $vmName ===" -ForegroundColor Cyan
    Write-Host "  State      : $($vm.State)"
    Write-Host "  Checkpoints: $(@(Get-VMSnapshot -VM $vm -ErrorAction SilentlyContinue).Count)"
    Write-Host "  Disks to delete:"
    if ($files) { $files | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow } } else { Write-Host "    (none)" }
    Write-Host "  Folder to delete: $(if ($folderToDelete) { $folderToDelete } else { '(none - not a dedicated VM folder)' })"
    $kept = Get-VMDiskPaths $vm | ForEach-Object { Get-VhdChain $_ } |
            ForEach-Object { [IO.Path]::GetFullPath($_) } | Sort-Object -Unique |
            Where-Object { $files -notcontains $_ }
    if ($kept) { $kept | ForEach-Object { Write-Host "  Kept (template/shared): $_" -ForegroundColor Green } }

    if (-not $PSCmdlet.ShouldProcess($vmName, "Delete VM and all its files")) {
        [pscustomobject]@{ VM = $vmName; Result = "Skipped" }
        continue
    }

    try {
        if ($vm.State -ne "Off") {
            Stop-VM -VM $vm -TurnOff -Force
            Write-Host "  [OK] VM turned off" -ForegroundColor Green
        }

        Remove-VM -VM $vm -Force           # removes config + checkpoint metadata (not the VHDX files)
        Write-Host "  [OK] VM removed from Hyper-V" -ForegroundColor Green

        Start-Sleep -Seconds 2             # let vmms release file handles
        foreach ($f in $files) {
            if (Test-Path $f) { Remove-Item -Path $f -Force; Write-Host "  [OK] Deleted $f" -ForegroundColor Green }
        }

        if ($folderToDelete -and (Test-Path $folderToDelete)) {
            Remove-Item -Path $folderToDelete -Recurse -Force
            Write-Host "  [OK] Deleted folder $folderToDelete" -ForegroundColor Green
        }
        [pscustomobject]@{ VM = $vmName; Result = "Deleted" }
    } catch {
        Write-Warning "  $vmName : $($_.Exception.Message)"
        [pscustomobject]@{ VM = $vmName; Result = "Error: $($_.Exception.Message)" }
    }
}

Write-Host ""
$summary | Format-Table -AutoSize
