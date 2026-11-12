# Lab 6: Change Tracking and Inventory (45 min)

[← Lab 5](05-azure-monitor.md) · [Overview](../README.md) · [Lab 7 →](07-microsoft-defender-for-cloud.md)

In this lab you get a live inventory of your server — software, services, files, registry — and you catch a change someone made. It answers the classic incident question: "what changed on this server last night?"

**What is it?** Change Tracking and Inventory keeps a record of what's installed and running on each server, and logs **every change** with a timestamp. Think of it as a CCTV camera on the server's configuration. It uses the Azure Monitor Agent from Lab 5 and sends data to a Log Analytics workspace.

> **Cost note:** the service is included in the Azure benefits (Lab 2, Part D). The **Log Analytics ingestion** it generates is still billed.

### Steps

1. Open your machine in **Azure Arc** > **Operations** > **Change tracking**.
2. Select **Enable change tracking and inventory feature with AMA** > **Enable**. The portal installs the **ChangeTracking-Windows** extension and creates a DCR named `ct-dcr-…`. Wait a few minutes for the deployment notification.
3. Open **Operations** > **Inventory** > **Software**. Find **Windows Admin Center** — you installed it in Lab 1. Look at **Services** too.
4. Make some changes on your VM, as an admin "doing something at night":

   ```
   Stop-Service -Name Spooler
   Set-Service  -Name Spooler -StartupType Disabled
   Install-WindowsFeature -Name Telnet-Client
   ```
5. Wait. Changes can take **up to 30 minutes** to appear. Use the time to check Lab 4 compliance.
6. Back in **Change tracking**, look at the **Changes** list. Filter on **Services**: you see the Print Spooler state and startup type change, with the time.
7. Query the same data in your workspace > **Logs**:

   ```
   ConfigurationChange
   | where TimeGenerated > ago(2h)
   | project TimeGenerated, Computer, ConfigChangeType, SvcName, SoftwareName, SvcState, SvcStartupType
   | order by TimeGenerated desc
   ```
8. Optional: in **Change tracking** > **Settings**, add a file path to watch, for example `C:\LabConfig\*.ini`, then create and edit a file there.
9. Put things back:

   ```
   Set-Service -Name Spooler -StartupType Automatic
   Start-Service -Name Spooler
   ```

### Check yourself

- Where does Change Tracking get its data path from? (The Azure Monitor Agent and a Change Tracking DCR.)
- Why does the security team like this? (A change that shouldn't have happened is visible with a time and a server name — the start of an investigation.)

### Customer talking points

- An always-on **inventory and change log** for every server, like a CMDB that updates itself.
- Faster troubleshooting: "it worked yesterday" becomes a list of exact changes.
- **Included** with Software Assurance or subscription licences through Windows Server Management enabled by Azure Arc; only ingestion is billed.
- Good opening question: "When an application breaks, how long does it take to find what changed?"

---

[← Lab 5](05-azure-monitor.md) · [Overview](../README.md) · [Lab 7 →](07-microsoft-defender-for-cloud.md)
