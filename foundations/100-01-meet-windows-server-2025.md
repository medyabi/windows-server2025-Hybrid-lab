# Lab 100-1: Meet Windows Server 2025 (30 min)

[Overview](README.md) · [Lab 100-2 →](100-02-editions-and-licensing.md)

In this lab you get to know your server. What version is it? Which edition? Is it activated? Is it the full desktop or Server Core? These are the first four questions any admin asks, and the first four a customer will ask you.

**What is Windows Server 2025?** It's the current Long-Term Servicing Channel release of Windows Server, built on the same code base as Windows 11 24H2 (build 26100). Think of it as the engine room of a company: it runs the file shares, the identities, the virtual machines and the business apps that people never see but always use.

### Steps

1. Connect to your VM with Remote Desktop and sign in.
2. Press **Win + R**, type `winver`, and press **Enter**. Note the version and the **OS build** (26100.x).
3. Open **PowerShell as administrator** and get the same facts in one line:

   ```powershell
   Get-ComputerInfo | Select-Object WindowsProductName, OsVersion, OsBuildNumber, CsNumberOfLogicalProcessors,
     @{ Name = "MemoryGB"; Expression = { [math]::Round($_.CsTotalPhysicalMemory / 1GB, 1) } }
   ```
4. Check the **edition** and the **install type**:

   ```powershell
   Get-WindowsEdition -Online
   (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
   ```

   `ServerDatacenter` is the edition. `Server` means **Desktop Experience** (the full GUI). On **Server Core**, the same command returns `Server Core`.
5. Check the **activation**:

   ```powershell
   cscript //nologo $env:windir\system32\slmgr.vbs /dli
   ```

   Look at **License Status** (Licensed) and the **channel**. Your VM is activated by its Hyper-V host, without a product key: that's **Automatic Virtual Machine Activation (AVMA)**. It works because the host runs Datacenter edition. You'll see why in Lab 100-2.
6. Look at the taskbar, near the clock: there's an **Azure Arc** icon. In Windows Server 2025, the Arc setup wizard is installed by default. Don't run it now: connecting to Azure is Level 200.
7. Open **Server Manager** (it starts by itself at sign-in). Click **Local Server** and find the same information: computer name, workgroup, Windows Defender status, Remote Desktop **Enabled**, and the time zone.

### What's new in Windows Server 2025, in five lines

You don't need every feature. You need five you can explain in one sentence each:

- **Hotpatching**: security updates without a reboot, through Azure Arc (Level 200, Lab 3).
- **Azure Arc setup built in**, and **pay-as-you-go licensing** billed per core through Azure.
- **Secure by default**: SMB signing required by default, and Microsoft's security baseline applied in one command with OSConfig (Level 200, Lab 9).
- **Bigger Hyper-V**: up to 4 PB of memory and 2,048 logical processors per host, and GPU partitioning with live migration.
- **Hyperconverged improvements** in Datacenter: Network ATC, thin-provisioned Storage Spaces Direct volumes, workgroup clusters (Level 400).

### Check yourself

- How do you tell Desktop Experience from Server Core in PowerShell? (The `InstallationType` value: `Server` or `Server Core`.)
- Why is your VM activated with no product key? (AVMA: the Datacenter host activates its Windows Server guests.)
- What's the build number of Windows Server 2025? (26100.)

### Customer talking points

- Windows Server 2025 is the **current long-term release**: 5 years of mainstream support plus 5 years of extended support.
- Choose **Server Core** for infrastructure roles: smaller attack surface and fewer updates. Choose **Desktop Experience** when an app or a team needs the GUI.
- The headline for most customers is **hotpatching**: from 12 reboots a year to about 4.

---

[Overview](README.md) · [Lab 100-2 →](100-02-editions-and-licensing.md)
