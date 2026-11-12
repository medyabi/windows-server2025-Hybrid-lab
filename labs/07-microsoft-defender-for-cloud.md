# Lab 7: Microsoft Defender for Cloud (60 min)

[← Lab 6](06-change-tracking-and-inventory.md) · [Overview](../README.md) · [Lab 8 →](08-windows-management-from-azure.md)

In this lab your on-premises server gets the same protection as an Azure VM: security recommendations, a secure score, endpoint protection and alerts. And you trigger a safe test alert to see it end to end.

**Two layers, two prices:**

- **Foundational CSPM** (free) — security recommendations and a **secure score** for your resources.
- **Defender for Servers** (paid, Plan 1 or Plan 2) — threat protection. It deploys **Microsoft Defender for Endpoint** on the server, adds vulnerability management, and Plan 2 adds features like agentless scanning, OS configuration assessment and file integrity monitoring.

> **Cost note:** Defender for Servers is **not** part of the Azure benefits. Turning it on starts a **30-day trial** that can't be paused or extended. In a shared lab subscription, the **instructor** turns it on once, and turns it off after the session.

### Steps

**Part A — Instructor: turn on the plan**

1. **Microsoft Defender for Cloud** > **Environment settings** > select the lab subscription.
2. Toggle **Servers** to **On**. It defaults to **Plan 2**; use **Change plans** to pick Plan 1 if you only need endpoint protection. Select **Save**.

**Part B — Everyone: your server in Defender for Cloud**

3. Open your machine in **Azure Arc** > **Extensions**. After a while you see **MDE.Windows** — Defender for Endpoint, deployed automatically.
4. In **Defender for Cloud** > **Inventory**, filter on your resource group. Select your server and look at its **recommendations** and their **severity**.
5. Open **Recommendations** and pick one for your server. Read the **remediation steps**. Note which ones Lab 9 (OSConfig) will solve.
6. Open **Secure score** and find your resource group's contribution.

**Part C — Trigger a safe test alert**

Microsoft documents two safe ways to check that detection works. Both create **test** alerts only.

7. **Sample alerts (fastest):** in **Defender for Cloud** > **Security alerts**, select **Sample alerts**, pick the subscription and the **Defender for Servers** plan, then **Create sample alerts**. They appear after a few minutes, for simulated resources.
8. **A real test on your server:** check that **MDE.Windows** is installed (step 3). Then, in **Command Prompt as administrator** on your VM, run the documented validation command:

   ```
   powershell.exe -NoExit -ExecutionPolicy Bypass -WindowStyle Hidden $ErrorActionPreference = 'silentlycontinue';(New-Object System.Net.WebClient).DownloadFile('http://127.0.0.1/1.exe', 'C:\test-MDATP-test\invoice.exe');Start-Process 'C:\test-MDATP-test\invoice.exe'
   ```

   The window closes by itself. It downloads nothing real — the address is the server itself.
9. Within about 10 minutes, open **Security alerts**. You see an alert for **your** server. Open it and look at the details: what, where, when, and the suggested response.

### Check yourself

- What's free and what's paid? (Recommendations and secure score: free. Threat protection with Defender for Servers: paid, per server.)
- Does the customer need a separate Defender for Endpoint server licence? (No — Defender for Servers includes it.)

### Customer talking points

- **One security console** for Azure, on-premises and other clouds. Arc is what brings the on-premises servers in.
- Start with **free recommendations** to show the gaps, then size **Plan 1 vs Plan 2** on what the customer needs to detect and prove.
- Defender alerts can flow into **Microsoft Sentinel** for the SOC.
- Good opening question: "Do your on-premises servers have the same EDR and security reporting as your cloud VMs?"

---

[← Lab 6](06-change-tracking-and-inventory.md) · [Overview](../README.md) · [Lab 8 →](08-windows-management-from-azure.md)
