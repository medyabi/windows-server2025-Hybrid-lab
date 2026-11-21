# Lab 100-4: Manage and monitor your server (30 min)

[← Lab 100-3](100-03-roles-and-features.md) · [Overview](README.md) · [Lab 100-5 →](100-05-storage-basics.md)

In this lab you look after your server like an admin does every day: change basic settings without the GUI, run commands remotely, read the event logs and check performance. These are the skills that keep a server healthy, and the ones customers expect their partner to have.

**Why learn this without the GUI?** Because the best servers have no GUI. **Server Core** is smaller, safer and needs fewer updates, and many customers run it for infrastructure roles. Think of it like a car with no dashboard screen: it drives the same, you just use the keys and the pedals.

### Steps

**Part A: SConfig, the text menu**

1. Open **PowerShell as administrator** and type:

   ```powershell
   sconfig
   ```

   This is the menu you get on Server Core. Look at what it covers: computer name, domain, Windows Update, Remote Desktop, network settings, date and time.
2. Type **6** (or the number shown for **Install updates**) to see the update options, then go back. Don't change the computer name or the network: you'd lose your connection.
3. Type **15** (or the number shown for **Exit to command line (PowerShell)**) to leave.

**Part B: PowerShell remoting**

4. Remoting lets you run commands on many servers at once. It's on by default on Windows Server. Check it:

   ```powershell
   Get-Service WinRM
   Test-WSMan -ComputerName localhost
   ```
5. Run a command "remotely" on your own server (with a domain, you'd put 10 server names here):

   ```powershell
   Invoke-Command -ComputerName localhost -ScriptBlock { Get-Service | Where-Object Status -eq Running | Measure-Object }
   ```

**Part C: event logs**

6. The **System** log is the first place to look when something goes wrong. Show the last 10 events, then only the errors:

   ```powershell
   Get-WinEvent -LogName System -MaxEvents 10 | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName
   Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 | Select-Object TimeCreated, Id, Message
   ```
7. Find when the server last started (event 6005, "The Event log service was started"):

   ```powershell
   Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 6005 } -MaxEvents 1 | Select-Object TimeCreated
   ```
8. Open **Event Viewer** (`eventvwr.msc`) and find the same events in **Windows Logs** > **System**. Use **Filter Current Log** to show only **Error**.

**Part D: performance**

9. Measure the CPU and free memory for 5 seconds:

   ```powershell
   Get-Counter -Counter '\Processor(_Total)\% Processor Time', '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 5
   ```
10. Open **Task Manager** (Ctrl + Shift + Esc) > **Performance**, then **Open Resource Monitor** at the bottom. Find which process uses the most CPU and memory.
11. Check which updates are installed:

    ```powershell
    Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
    ```

### Check yourself

- Which tool configures Server Core without a GUI? (SConfig, or PowerShell.)
- Where do you look first when a server misbehaves? (The **System** event log, filtered on errors.)
- Why does remoting matter? (One command runs on many servers, which is how admins manage at scale.)

### Customer talking points

- **Server Core** is the recommended install for infrastructure roles: smaller, safer, fewer reboots. SConfig and PowerShell make it easy to manage.
- **PowerShell remoting** is on by default: the base for automation, and for tools like Windows Admin Center.
- For many servers at once, the next step is **Azure Monitor and Azure Arc** (Level 200): the same logs and counters, in one place, with alerts.

---

[← Lab 100-3](100-03-roles-and-features.md) · [Overview](README.md) · [Lab 100-5 →](100-05-storage-basics.md)
