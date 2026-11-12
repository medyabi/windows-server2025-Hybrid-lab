# Lab 5: Azure Monitor (60 min)

[← Lab 4](04-azure-policy-and-machine-configuration.md) · [Overview](../README.md) · [Lab 6 →](06-change-tracking-and-inventory.md)

In this lab you see your server's performance and event logs in Azure, and you query them with KQL. That's the answer to "what replaces SCOM for our hybrid servers?"

**How does it work?** Three pieces work together:

- **Azure Monitor Agent (AMA)** — an Arc extension that collects data on the server.
- **Data collection rule (DCR)** — says **what** to collect (counters, event logs) and **where** to send it.
- **Log Analytics workspace** — the database where the data lands and where you query it with **KQL** (Kusto Query Language).

Think of the agent as a postman, the DCR as the delivery list, and the workspace as the mailbox.

> **Cost note:** Azure Monitor isn't part of the Azure benefits. Log Analytics **ingestion is billed** per GB. In the lab, keep collection small and delete the workspace at the end.

### Steps

**Part A — Workspace and VM insights**

1. In the portal, create a **Log Analytics workspace** named `law-presales-<yourname>` in your resource group, same region as your Arc server. You reuse it in Labs 6 and 8.
2. Open your machine in **Azure Arc** > **Monitoring** > **Insights** > **Configure**.
3. Select **Customize infrastructure monitoring** and choose your workspace. Then **Review + Enable** > **Enable**. The portal installs the Azure Monitor Agent extension and creates the DCR.
4. Open **Extensions** on your machine. You should see **AzureMonitorWindowsAgent** with status **Succeeded**.
5. After 10–15 minutes, go back to **Insights** and look at the **Performance** charts: CPU, memory, disk, network.

**Part B — Collect event logs and query them**

6. Search for **Data collection rules** > **Create**:
   - Name `dcr-events-<yourname>`, your resource group and region, platform **Windows**.
   - **Resources**: add your Arc server.
   - **Collect and deliver**: add a data source **Windows Event Logs**, select **System** and **Application** with levels **Critical**, **Error** and **Warning**. Destination: your workspace.
7. On your VM, write a test error event:

   ```
   New-EventLog -LogName Application -Source PresalesLab -ErrorAction SilentlyContinue
   Write-EventLog -LogName Application -Source PresalesLab -EventId 999 -EntryType Error -Message "Presales lab test error"
   ```
8. After about 10 minutes, open your workspace > **Logs** and run:

   ```
   Heartbeat
   | where TimeGenerated > ago(1h)
   | summarize LastSeen = max(TimeGenerated) by Computer
   
   Event
   | where Source == "PresalesLab"
   | project TimeGenerated, Computer, EventID, RenderedDescription
   ```
9. From the second query, select **New alert rule**. Create an alert that fires when the count is greater than 0, with an action group that emails you. Write the test event again and wait for the mail.

### Check yourself

- What decides which events are collected — the agent or the DCR? (The DCR. One DCR can target many servers.)
- Why does the customer care about the workspace region? (Data residency, and the DCR must be in the same region as the workspace.)

### Customer talking points

- **One monitoring platform** for Azure VMs and on-premises servers, with the same dashboards, queries and alerts.
- A modern path off **SCOM** for hybrid servers — no management servers or SQL databases to run.
- The cost model is **pay per GB ingested**. Help the customer size it: collect what they will act on, not everything.
- Good opening question: "How do you know a server is in trouble before users call?"

---

[← Lab 4](04-azure-policy-and-machine-configuration.md) · [Overview](../README.md) · [Lab 6 →](06-change-tracking-and-inventory.md)
