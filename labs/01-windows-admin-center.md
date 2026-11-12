# Lab 1: Windows Admin Center (45 min)

[← Overview](../README.md) · [Overview](../README.md) · [Lab 2 →](02-azure-arc-onboarding-and-azure-benefits.md)

By the end of this lab you manage your server from a web browser, with no MMC consoles and no RDP. That's the demo customers remember.

**What is Windows Admin Center (WAC)?** It's a free, browser-based management tool for Windows Server. You install a small **gateway** on one machine, and from there you manage servers, clusters and PCs over the network. Think of it as Server Manager, Event Viewer, Device Manager and PowerShell, all in one browser tab. On Windows Server it listens on port **443**.

### Steps

1. RDP to your VM and open **PowerShell as administrator**.
2. Download the installer:

   ```
   Start-BitsTransfer -Source "https://aka.ms/WACdownload" -Destination ".\WindowsAdminCenter.exe"
   ```
3. Run `.\WindowsAdminCenter.exe` and follow the wizard:
   - Accept the licence terms.
   - Choose **Express setup**.
   - On **Select TLS certificate**, choose **Generate a self-signed certificate**. It's fine for a lab and expires after 60 days. In production, the customer uses a certificate from their own CA.
   - Keep **automatic updates** on, then **Install**.
4. Tick **Start Windows Admin Center** and select **Finish**. Sign in with your local **Administrator** account.
5. Your server appears under **All connections**. Click it and take the tour:
   - **Overview**: CPU, memory, disk and network in real time.
   - **Events**, **Services**, **Processes**: what you would normally do in three different consoles.
   - **PowerShell**: a remote PowerShell session in the browser.
6. Make a real change from WAC:
   - **Roles & features** > install **Windows Server Backup**.
   - **Firewall** > create an inbound rule allowing **TCP 8080**.
   - **Updates** > check for updates. Don't install them yet — we need this VM for Lab 3.
7. Open **Azure hybrid center** and look at the services offered. You'll use Azure Arc in Lab 2.

### Check yourself

- Why does the customer need only **one** WAC gateway for many servers?
- What would you change before putting WAC in production? (A trusted certificate, and who's allowed to sign in.)

### Customer talking points

- WAC is **included with Windows Server** at no extra cost. No agent is installed on the managed servers.
- It replaces most of the MMC tools and works great for **Server Core**, where there's no desktop to RDP into.
- It's the easy on-ramp to hybrid: from the same browser, connect servers to **Azure Arc**, backup and monitoring.
- Good opening question: "How do your admins manage servers today — RDP to each one?"

---

[← Overview](../README.md) · [Overview](../README.md) · [Lab 2 →](02-azure-arc-onboarding-and-azure-benefits.md)
