# Lab 100-2: Editions and licensing (30 min)

[← Lab 100-1](100-01-meet-windows-server-2025.md) · [Overview](README.md) · [Lab 100-3 →](100-03-roles-and-features.md)

In this lab you learn to answer the two questions every customer asks before buying: **which edition**, and **how many licences**. Then you size three real-looking customers.

> **Important:** licensing rules come from the Microsoft Product Terms and change over time. Use this lab to understand the model and to ask the right questions. For a quote, always check the current terms with your licensing team or distributor.

### Three editions

Think of the editions like car models built on the same engine. The engine (Windows Server) is the same; what changes is how many passengers you're allowed to carry and a few premium options.

| | **Standard** | **Datacenter** | **Datacenter: Azure Edition** |
| --- | --- | --- | --- |
| Best for | Physical servers, or hosts with few VMs | Virtualization hosts, hyperconverged clusters | VMs running in Azure or on Azure Local |
| Windows Server VMs covered when all cores are licensed | 2 | Unlimited | Not applicable (runs in Azure or Azure Local) |
| Storage Spaces Direct (hyperconverged storage) | No | Yes | Yes |
| SDN Network Controller | No | Yes | Yes |
| Host Guardian Hyper-V support (shielded VMs) | No | Yes | Yes |
| Can activate guest VMs with AVMA | No | Yes | Yes |
| Hotpatching | Through Azure Arc | Through Azure Arc | Built in |

Almost everything else is the same in all editions: Hyper-V, Failover Clustering, Storage Replica, SMB over QUIC, Network ATC, Active Directory, Windows Admin Center support.

### How Windows Server is licensed

There are two ways to pay.

**1. Per core, the classic way (perpetual licences, often with Software Assurance):**

- License **every physical core** of the server.
- Minimum **8 cores per processor** and **16 cores per server**, even if the server has fewer.
- **Standard**: licensing all cores covers **2** Windows Server VMs. For 4 VMs, license all the cores twice, and so on.
- **Datacenter**: licensing all cores covers **unlimited** Windows Server VMs on that host.
- Users and devices also need **CALs** (client access licences), and **RDS CALs** for Remote Desktop Services.

**2. Pay-as-you-go through Azure Arc (Windows Server 2025 only):**

- Connect the server to Azure Arc, turn on pay-as-you-go, and pay **per physical core, per hour**, on your Azure bill.
- **Same price for Standard and Datacenter.**
- **No CALs** for standard use (RDS CALs are still needed).
- It covers only the machine where it's enabled: **no rights for VMs on that host**, so no AVMA.
- 7-day free trial. Billing continues while it's on, even if the server is off, so disable it when you stop using it.

**And Software Assurance?** Customers with active SA (or subscription licences) unlock **Windows Server Management enabled by Azure Arc**: Update Manager, Change Tracking, Machine Configuration, Windows Admin Center in Azure, Best Practices Assessment and more. That's the whole Level 200 track.

### Steps

1. On your VM, in **PowerShell as administrator**, see which editions this installation can be upgraded to:

   ```powershell
   DISM /Online /Get-CurrentEdition
   DISM /Online /Get-TargetEditions
   ```

   You're already on Datacenter, the top on-premises edition, so there's nothing above it. On a Standard server, Datacenter would appear: upgrading in place is possible.
2. Look at how your VM is activated again:

   ```powershell
   cscript //nologo $env:windir\system32\slmgr.vbs /dli
   ```

   AVMA works only because the **host** runs Datacenter. On a Standard host, each guest would need its own key.
3. Now size these three customers. Write your answer, then open the solution.

   **Customer A.** One physical server, 1 processor with 12 cores, running Windows Server directly (no VMs): a file server.

   <details><summary>Solution</summary>

   Standard edition, **16 cores** (the server minimum, even with only 12 physical cores). Plus CALs for the users.

   </details>

   **Customer B.** One Hyper-V host, 2 processors with 16 cores each, running 6 Windows Server VMs today and growing.

   <details><summary>Solution</summary>

   32 physical cores. Standard would need the 32 cores licensed **3 times** (2 VMs each), so 96 core licences, and more as they grow. **Datacenter** licenses the 32 cores once and covers unlimited VMs: simpler and usually cheaper above roughly 10 to 12 VMs. Compare current prices to find the exact break-even point.

   </details>

   **Customer C.** A branch office with a small server they'll replace within the year, and no Software Assurance.

   <details><summary>Solution</summary>

   A good case for **pay-as-you-go with Azure Arc**: no upfront purchase, no CALs for standard use, and they stop paying when they stop using it. Arc also gives them Azure management for that server.

   </details>

### Check yourself

- What's the minimum number of core licences for a server with one 6-core processor? (16.)
- When does Datacenter beat Standard? (When a host runs many Windows Server VMs, or needs Storage Spaces Direct or SDN.)
- Does pay-as-you-go cover the VMs on a host? (No. Each machine needs its own licence.)

### Customer talking points

- **Few VMs per host: Standard. Many VMs, or hyperconverged: Datacenter.**
- Pay-as-you-go turns Windows Server into an **operating expense**, billed through Azure, with no CALs for standard use.
- Software Assurance isn't just upgrade rights anymore: on Windows Server 2025 it unlocks **Azure management benefits at no extra licence cost**.

---

[← Lab 100-1](100-01-meet-windows-server-2025.md) · [Overview](README.md) · [Lab 100-3 →](100-03-roles-and-features.md)
