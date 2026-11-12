# Lab 3: Hotpatching with Azure Arc (45 min)

[← Lab 2](02-azure-arc-onboarding-and-azure-benefits.md) · [Overview](../README.md) · [Lab 4 →](04-azure-policy-and-machine-configuration.md)

In this lab you turn on **Hotpatch** and install a security update with **no reboot**. For a customer running 24/7 workloads, this is the feature that gets attention.

**What is Hotpatch?** A normal security update replaces files on disk, so the server must restart to load them. A hotpatch changes the code **in memory**, while it runs. Think of changing a tyre while the car keeps driving.

Hotpatch follows a **quarterly rhythm**:

- **Baseline months** — January, April, July, October. A full cumulative update. **Restart required.**
- **Hotpatch months** — the other eight months. Security updates only. **No restart.**

So instead of 12 reboots a year, the server restarts about 4 times.

**Requirements:** Windows Server 2025 Standard or Datacenter, connected to Azure Arc, with **virtualization-based security (VBS)** running. On Hyper-V that means a **Generation 2** VM with **Secure Boot** — your VM already has both.

### Steps

1. On your VM, check that VBS is running:

   ```
   Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard |
     Select-Object -ExpandProperty VirtualizationBasedSecurityStatus
   ```

   **2** means running. If you get anything else, enable it and restart:

   ```
   New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -PropertyType DWord -Value 1 -Force
   Restart-Computer
   ```
2. Check the OS build with `winver`. Hotpatch needs build **26100.1742 or later** — our ISO is far newer.
3. In the portal, go to **Azure Arc > Machines** > your server > **Hotpatch** > **Confirm**.
4. Wait about **10 minutes**. The status moves from **Pending** to enabled. If it stays on Pending, ask your instructor to check the Arc agent.
5. Open **Updates** (Azure Update Manager) > **Check for updates**. Look at the update list: a hotpatch update is marked as not needing a reboot.
6. Select **One-time update**, choose the available security update, and install it.
7. When it finishes, open **History** in Update Manager. Look at the **reboot status** column. Then check uptime on the VM — it didn't restart:

   ```
   (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
   ```

> **If the update still asks for a reboot:** the VM may not be on the expected baseline. It then gets a normal update until the next baseline month (January), and hotpatches work from there. That's also a real-world lesson: hotpatch only works when servers stay on the baseline.

### Check yourself

- How many restarts a year does a hotpatched server need for security updates? (About 4, in baseline months.)
- Why does Hotpatch need VBS? (The in-memory patching relies on the virtualization-based protection layer.)

### Customer talking points

- **From 12 to about 4 reboots a year** for security updates, on servers in their own datacenter.
- Since **19 May 2026**, Hotpatch for Arc-enabled Windows Server 2025 Standard and Datacenter has **no extra cost** — Hyper-V, VMware or any other platform.
- Patches land **the day they're released**, instead of waiting for the next maintenance window. Shorter exposure to known vulnerabilities.
- It's a strong reason to **move to Windows Server 2025 and connect to Arc** in the same project.

---

[← Lab 2](02-azure-arc-onboarding-and-azure-benefits.md) · [Overview](../README.md) · [Lab 4 →](04-azure-policy-and-machine-configuration.md)
