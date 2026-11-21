# Lab 100-3: Roles and features (30 min)

[← Lab 100-2](100-02-editions-and-licensing.md) · [Overview](README.md) · [Lab 100-4 →](100-04-manage-and-monitor.md)

In this lab you give your server a job. A fresh Windows Server does almost nothing: you choose what it becomes by adding **roles** and **features**. You make it a file server and a web server, once with the mouse and once with PowerShell.

**Role or feature?** A **role** is the server's job for other machines: file server, web server, DNS, Hyper-V, Active Directory. A **feature** is a tool that helps the server itself: BitLocker, Failover Clustering, Windows Server Backup. Think of a restaurant: the roles are what you serve customers (a kitchen, a bar), the features are the equipment behind the scenes (the dishwasher, the fridge).

### Steps

**Part A: in Server Manager**

1. Open **Server Manager** > **Manage** > **Add Roles and Features**.
2. Click **Next** until **Server Roles**. Expand **File and Storage Services** > **File and iSCSI Services** and tick **File Server**. Click **Next**.
3. On **Features**, don't add anything. Click **Next**, then **Install**. When it's done, click **Close**.
4. Back in Server Manager, a new **File and Storage Services** entry appears on the left. That's the role's management page.

**Part B: in PowerShell**

5. Open **PowerShell as administrator**. List what's installed:

   ```powershell
   Get-WindowsFeature | Where-Object Installed | Select-Object Name, DisplayName
   ```

   You see `FS-FileServer`, the File Server role you just added.
6. Install the **web server (IIS)** with its management tools, in one line:

   ```powershell
   Install-WindowsFeature -Name Web-Server -IncludeManagementTools
   ```

   Check the **Restart Needed** column: here it says **No**. Some roles do need a restart.
7. Test the web server:

   ```powershell
   (Invoke-WebRequest -Uri http://localhost -UseBasicParsing).StatusCode
   ```

   `200` means the default IIS page answers. You can also open **http://localhost** in Edge.
8. Use the file server role: create a folder and share it.

   ```powershell
   New-Item -Path C:\Shares\Sales -ItemType Directory -Force
   New-SmbShare -Name Sales -Path C:\Shares\Sales -FullAccess Administrators -ReadAccess Users
   Get-SmbShare
   Test-Path \\localhost\Sales
   ```
9. See what a role brings with it. Find the IIS service and the firewall rules it added:

   ```powershell
   Get-Service W3SVC
   Get-NetFirewallRule | Where-Object DisplayName -like 'World Wide Web*' | Select-Object DisplayName, Enabled
   ```
10. Now add a **feature**, a tool for the server itself: Windows Server Backup.

    ```powershell
    Install-WindowsFeature -Name Windows-Server-Backup
    wbadmin get versions
    ```

    No backup exists yet, so `wbadmin` says so. The tool is ready; a real backup also needs a separate target disk or a network share.

> **Note:** keep a server to the roles it needs. Every extra role is more updates, more open ports and more attack surface.

### Check yourself

- Is Hyper-V a role or a feature? (A role: it serves virtual machines.)
- Which PowerShell command lists what's installed? (`Get-WindowsFeature`, filtered on `Installed`.)
- Why script the install instead of clicking? (It's repeatable: the same command builds 1 or 100 identical servers.)

### Customer talking points

- One operating system, many jobs: Windows Server becomes a file server, web server, domain controller or virtualization host **by adding roles**, with no extra product to buy.
- Everything in Server Manager can be done in **PowerShell**, which means automation and consistency at scale.
- Install only what you need: **less attack surface, fewer updates**.

---

[← Lab 100-2](100-02-editions-and-licensing.md) · [Overview](README.md) · [Lab 100-4 →](100-04-manage-and-monitor.md)
