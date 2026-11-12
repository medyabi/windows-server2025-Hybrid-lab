# Lab 2: Azure Arc onboarding and Azure benefits (75 min)

[← Lab 1](01-windows-admin-center.md) · [Overview](../README.md) · [Lab 3 →](03-hotpatching-with-azure-arc.md)

In this lab your on-premises VM shows up in the Azure portal, next to cloud VMs, and you manage its updates from there. That's the core of every hybrid conversation.

**What is Azure Arc?** Azure Arc projects a server that runs **outside Azure** into Azure as a resource. A small agent, the **Azure Connected Machine agent**, runs on the server and talks to Azure over HTTPS (port 443). Think of it as giving your server an Azure passport: it stays at home, but Azure now knows it, can tag it, apply policy to it and update it.

### Steps

**Part A — Generate the onboarding script (Azure portal)**

1. Sign in to the [Azure portal](https://portal.azure.com) and create a resource group named `rg-presales-<yourname>`.
2. Search for **Azure Arc** > **Machines** > **Onboard/Create** > **Onboard existing machines**.
3. On **Basics**:
   - Pick your subscription and `rg-presales-<yourname>`.
   - **Region**: France Central. It supports Windows Admin Center in Azure (Lab 8).
   - **Operating system**: Windows.
   - **Connectivity method**: Public endpoint.
   - **Authentication method**: Authenticate machines manually.
4. On **Tags**, add `Owner = <yourname>` and `Purpose = presales-lab`.
5. On **Download and run script**, select **Register** if the resource providers aren't registered yet, then **Download** the script.

**Part B — Run it on your VM**

6. Copy the script to your VM (RDP clipboard works for text) and run it in **PowerShell as administrator**.
7. When prompted, sign in with your Azure account. The script installs the agent and connects the server.
8. Check the connection from the VM:

   ```
   azcmagent show
   ```

   **Agent Status** should be **Connected**. You also see the resource name, resource group and region.

**Part C — Manage it from Azure**

9. In the portal, open **Azure Arc > Machines** and select your server. Look at **Overview** and **Properties**: OS version, cores, memory, IP addresses — an inventory with no extra tool.
10. Open **Updates** (Azure Update Manager) > **Check for updates**. After a few minutes you see the missing updates. **Don't install them** — Lab 3 needs them.
11. Open **Extensions**. This is how Azure pushes extra capabilities to the server (monitoring, Defender, scripts) without logging in.

**Part D — Activate Azure benefits (Windows Server Management enabled by Azure Arc)**

Why does this matter? A customer with **Software Assurance** or **subscription licences** gets a set of Azure management services for their Arc servers **at no extra cost** — but only after they **attest** it, server by server. Arc doesn't guess it from the licence.

What the attestation unlocks:

| Service | Used in lab |
| --- | --- |
| Azure Update Manager | 2, 3 |
| Azure Machine Configuration | 4 |
| Change Tracking and Inventory | 6 |
| Windows Admin Center in Azure | 8 |
| Best Practices Assessment | 8 |
| Remote Support | 8 |
| Azure Site Recovery configuration, Network HUD, Azure File Sync discount | — |

> **This checkbox is a legal statement.** In our lab, the instructor confirms the licences qualify before anyone ticks it. With customers, never tick it for them.

12. On your VM, check the agent version. Benefits need **1.47 or later**:

    ```
    azcmagent version
    ```
13. In the portal, open your machine > **Licenses** > **Windows Server**.
14. Under **License details**, check that **License status** is **Licensed** and **Arc agent status** is **Connected**. Only licensed, connected servers are eligible.
15. Under **Azure benefits**, tick **Activate Azure benefits** and select **Confirm**. Within about 10 minutes the benefits show as **Activated**.
16. Look at **Pay-as-you-go** on the same page. It's greyed out with "machine must be unlicensed to be eligible". Pay-as-you-go is the other route to the same benefits, for servers without a licence: Windows Server is billed monthly on the Azure subscription.
17. To activate many servers at once, use **Azure Arc > Licenses > Azure Benefits - Windows Server**, select the servers and **Activate benefits**.

**Still billed after activation:** Log Analytics ingestion (Change Tracking, Best Practices Assessment, Azure Monitor), the Azure Site Recovery service itself, storage and networking. **Hotpatch** isn't part of this programme — it's available to every Arc-enabled Windows Server 2025, with or without SA.

### Check yourself

- Which port must be open outbound for Arc to work? (TCP 443.)
- What happens to the server's workloads if the internet link drops? (Nothing. The server keeps running; Azure just loses visibility until it reconnects.)

### Customer talking points

- **One control plane** for servers in the datacenter, at the edge, and in other clouds: same portal, same RBAC, same tags, same policy.
- Connecting a server to Arc is free; some services you turn on afterwards are billed. Check current pricing before quoting a number.
- Arc unlocks Windows Server benefits like **Hotpatch** (Lab 3), **pay-as-you-go licensing** and **security baselines at scale** with Azure Policy.
- Good opening question: "How many tools do you use today to patch and inventory your servers?"

---

[← Lab 1](01-windows-admin-center.md) · [Overview](../README.md) · [Lab 3 →](03-hotpatching-with-azure-arc.md)
