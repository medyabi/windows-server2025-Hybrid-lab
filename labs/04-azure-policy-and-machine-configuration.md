# Lab 4: Azure Policy and Machine Configuration (45 min + 30 min wait)

[← Lab 3](03-hotpatching-with-azure-arc.md) · [Overview](../README.md) · [Lab 5 →](05-azure-monitor.md)

In this lab you audit **every** server in a scope from Azure, with one assignment. That's how the customer proves compliance across hundreds of servers. Your server isn't hardened yet — you'll do that in Lab 9 and watch this compliance go up.

**What's the difference?** **Azure Policy** sets rules on Azure resources. **Machine Configuration** (formerly Guest Configuration) carries those rules **inside the operating system**, through the Arc agent. Think of it as Group Policy that works for any server — domain-joined or not, on-premises or in another cloud — with one compliance dashboard.

### Steps

1. In the portal, search for **Policy** > **Definitions**.
2. Search for **Windows machines should meet requirements of the Azure compute security baseline** and open it. For Windows Server 2025, this baseline is powered by the same **OSConfig** engine you'll use in Lab 9.
3. Select **Assign policy**:
   - **Scope**: your resource group `rg-presales-<yourname>`.
   - If the portal offers to deploy the **Machine Configuration prerequisites**, accept.
   - **Parameters**: set **Include Arc connected servers** to **true**.
   - **Review + create** > **Create**.
4. The first evaluation takes about **30 minutes**. Start Lab 5 and come back.
5. Open **Policy** > **Compliance** and select your assignment. Your server shows **Compliant** or **Non-compliant**.
6. Select your server to see **each rule**, its expected value and its current value. Many will fail — the server still has default settings. Note the failing rules: Lab 9 fixes most of them.
7. Open your machine in **Azure Arc** > **Operations** > **Machine Configuration**. You see the same assignment, from the server's point of view.

### Check yourself

- Why do so many rules fail? (The server still has default settings. Azure Policy here only audits and reports; you harden the server in Lab 9.)
- What's the scope difference with Group Policy? (Azure Policy targets subscriptions, resource groups and tags. GPO targets domains and OUs.)

### Customer talking points

- **One compliance dashboard** for servers in the datacenter, the edge and other clouds — including servers that aren't in a domain.
- Audit reports are ready for **auditors and regulators**, without collecting RSoP from each server.
- **Azure Machine Configuration is included** in Windows Server Management enabled by Azure Arc (Part D of Lab 2) for customers with SA or subscription licences.
- Good opening question: "How do you prove to your auditors that all your servers follow your security policy?"

---

[← Lab 3](03-hotpatching-with-azure-arc.md) · [Overview](../README.md) · [Lab 5 →](05-azure-monitor.md)
