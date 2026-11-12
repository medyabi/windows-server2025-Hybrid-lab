# Lab 8: Windows management from Azure (60 min + up to 4 h for the first assessment)

[← Lab 7](07-microsoft-defender-for-cloud.md) · [Overview](../README.md) · [Lab 9 →](09-security-baseline-with-osconfig.md)

In this lab you manage the server from the Azure portal with **no VPN and no inbound port**, run a best-practices health check, and see how Microsoft Support can get controlled access. All three come with the Azure benefits from Lab 2, Part D.

> **Start Part B first.** The first Best Practices Assessment can take **up to 4 hours** to return results. Launch it, do Part A, and check the results at the end of the day.

### Steps

**Part B — Best Practices Assessment (start it now)**

1. Open your machine in **Azure Arc** > **Windows management** > **Best Practices Assessment**.
2. Select **Get Started**. Choose your resource group and your workspace `law-presales-<yourname>`, then **Set up**. It installs three extensions (assessment platform, Windows Server assessment, Azure Monitor Agent) — up to 15 minutes.
3. When it's ready, select **Run assessment**. Come back later for the results.

**Part A — Windows Admin Center in Azure**

> **Heads-up:** turning this on **replaces** the Windows Admin Center you installed locally in Lab 1. Fine in the lab. With a customer who uses one WAC gateway to manage many servers, plan this first.

4. Give yourself the right role. On your machine, open **Access control (IAM)** > **Add role assignment** > **Windows Admin Center Administrator Login** > assign it to your account. Connecting needs this role even if you're Owner.
5. Open **Windows management** > **Windows Admin Center** > **Install**. Keep the default port. Wait for the extension to finish.
6. Select **Connect** and sign in with the VM's local **Administrator** account.
7. Use it like the local WAC from Lab 1: **Files**, **Registry**, **Services**, **PowerShell**. Then open **Remote Desktop** — a desktop session in the browser, through Azure, with no RDP port open on the server.

**Part C — Remote Support (walkthrough)**

8. Open **Windows management** > **Remote Support**. Read the page; don't grant access. The idea: when the customer opens a ticket, they give **Microsoft Support** time-limited (**just-in-time**) access to the server, with a **transcript** of every command and the right to revoke it at any time. It's for customers with a Microsoft professional support plan.

**Back to Part B**

9. When the assessment is complete, open **Best Practices Assessment** again. Look at the issues found, their **severity** and the **remediation** guidance. Keep the list — compare it after Lab 9.

### Check yourself

- Why doesn't WAC in Azure need an inbound port? (The Arc agent opens an **outbound** reverse-proxy connection. Azure comes to the server through it.)
- Which of these three services need a Log Analytics workspace? (Best Practices Assessment. Ingestion is billed.)

### Customer talking points

- Manage any Arc server from the portal **without VPN, jump host or public IP** — a strong story for branch offices and edge sites.
- **Best Practices Assessment** turns Microsoft's field experience into a to-do list for each server.
- **Remote Support** gives Microsoft engineers controlled, audited, time-limited access — no shared admin passwords.
- All three are **included** with Software Assurance or subscription licences through Windows Server Management enabled by Azure Arc.

---

[← Lab 7](07-microsoft-defender-for-cloud.md) · [Overview](../README.md) · [Lab 9 →](09-security-baseline-with-osconfig.md)
