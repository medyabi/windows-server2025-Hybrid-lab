# Lab 100-5: Storage basics (30 min)

[← Lab 100-4](100-04-manage-and-monitor.md) · [Overview](README.md) · [Level 200: Hybrid labs →](../README.md)

In this lab you add disks to your server, format them with the two Windows file systems, and share data over the network. Storage is behind almost every customer project: file servers, VMs, backups, databases.

**NTFS or ReFS?** **NTFS** is the classic file system: it boots Windows and works everywhere. **ReFS** (Resilient File System) is built for large volumes and virtualization: it checks its own data for corruption and makes some operations, like copying big VM files, much faster. Think of NTFS as a reliable family car and ReFS as a truck built for heavy loads: you don't drive a truck to the shop, and you don't move a house with a family car.

Your VM has only one disk, so you create **virtual disks** (VHDX files) inside it. They behave like real disks.

### Steps

1. Open **PowerShell as administrator** and look at the disks and volumes you have now:

   ```powershell
   Get-Disk | Select-Object Number, FriendlyName, BusType, PartitionStyle, @{ Name = "SizeGB"; Expression = { $_.Size / 1GB } }
   Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystem, FileSystemLabel, @{ Name = "SizeGB"; Expression = { [math]::Round($_.Size / 1GB, 1) } }
   ```
2. Create two 10 GB virtual disks and attach them. Windows uses **diskpart** for this:

   ```powershell
   New-Item -Path C:\Lab -ItemType Directory -Force | Out-Null
   @"
   create vdisk file="C:\Lab\data1.vhdx" maximum=10240 type=expandable
   attach vdisk
   create vdisk file="C:\Lab\data2.vhdx" maximum=10240 type=expandable
   attach vdisk
   "@ | Set-Content C:\Lab\vdisks.txt
   diskpart /s C:\Lab\vdisks.txt
   ```

   **Expandable** means the file starts small and grows as you write data, like a dynamic disk in Hyper-V.
3. The two new disks appear as **RAW** (empty). Initialize them, then format the first one **NTFS** and the second one **ReFS**:

   ```powershell
   $new = Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Sort-Object Number
   $new | Initialize-Disk -PartitionStyle GPT

   New-Partition -DiskNumber $new[0].Number -UseMaximumSize -DriveLetter N |
     Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data-NTFS" -Confirm:$false
   New-Partition -DiskNumber $new[1].Number -UseMaximumSize -DriveLetter R |
     Format-Volume -FileSystem ReFS -NewFileSystemLabel "Data-ReFS" -Confirm:$false
   ```
4. Compare the two volumes:

   ```powershell
   Get-Volume -DriveLetter N, R | Select-Object DriveLetter, FileSystem, FileSystemLabel, HealthStatus, SizeRemaining
   ```

   Open **File Explorer** > **This PC**: you now have **N:** and **R:**. Right-click each > **Properties** and compare the file system.
5. See ReFS speed for yourself. Create a 2 GB file on each volume, then copy it on the same volume and time the copy:

   ```powershell
   fsutil file createnew N:\big.bin 2147483648
   fsutil file createnew R:\big.bin 2147483648
   Measure-Command { Copy-Item N:\big.bin N:\copy.bin } | Select-Object TotalSeconds
   Measure-Command { Copy-Item R:\big.bin R:\copy.bin } | Select-Object TotalSeconds
   ```

   On ReFS, Windows Server 2025 uses **block cloning**: the copy only adds a pointer to the same data, so it's almost instant. This is why Hyper-V and backup products like ReFS.
6. Share a folder on the ReFS volume, and look at the SMB security settings of your server:

   ```powershell
   New-Item -Path R:\Projects -ItemType Directory | Out-Null
   New-SmbShare -Name Projects -Path R:\Projects -FullAccess Administrators -EncryptData $true
   Get-SmbShare -Name Projects | Select-Object Name, Path, EncryptData
   Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol, RequireSecuritySignature, EncryptData
   ```

   **EncryptData** on the share encrypts the traffic for that share. SMB1, the old and insecure version, is **off**.
7. Clean up (optional; your VM is reset after the slot anyway):

   ```powershell
   Remove-SmbShare -Name Projects -Force
   @"
   select vdisk file="C:\Lab\data1.vhdx"
   detach vdisk
   select vdisk file="C:\Lab\data2.vhdx"
   detach vdisk
   "@ | Set-Content C:\Lab\detach.txt
   diskpart /s C:\Lab\detach.txt
   ```

### Check yourself

- Which file system boots Windows? (NTFS. ReFS is for data volumes.)
- Why is a copy on ReFS so fast? (Block cloning: the new file points to the same blocks until one of them changes.)
- What does `-EncryptData $true` on a share protect? (The data while it travels on the network.)

### Customer talking points

- **ReFS** for VM storage, backup repositories and large data volumes: built-in integrity checks and very fast VM operations. **NTFS** for the system drive and general use.
- **SMB 3 encryption** protects file traffic with one setting, and Windows Server 2025 keeps old, insecure SMB1 off.
- The next step up is **Storage Spaces Direct** on Datacenter: pool the disks of several servers into one resilient storage system. That's Level 400.

---

[← Lab 100-4](100-04-manage-and-monitor.md) · [Overview](README.md) · [Level 200: Hybrid labs →](../README.md)

You've finished Level 100. Next, connect your server to Azure: **Level 200, Lab 1: [Windows Admin Center](../labs/01-windows-admin-center.md)**.
