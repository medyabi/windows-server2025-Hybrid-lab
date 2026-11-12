# Cleanup and reset

[← Lab 9](09-security-baseline-with-osconfig.md) · [Overview](../README.md)

Always clean Azure first, then the VM. If you delete the VM first, the Arc resource stays in Azure as a disconnected "ghost" server.

**1. Remove the server from Azure Arc** (on the VM, PowerShell as administrator):

```
azcmagent disconnect
```

Sign in when prompted. This deletes the Arc resource in Azure and disconnects the agent. Then delete your resource group `rg-presales-<yourname>` in the portal.

Deleting the resource group also removes your Log Analytics workspace, your DCRs and the policy assignment from Lab 4. The **instructor** then turns **Defender for Servers** off in **Defender for Cloud** > **Environment settings**, so billing stops after the session.

**2. Rebuild the VM** (instructor, on the Hyper-V host). This gives a clean, AVMA-activated VM in a few minutes:

```
.\scripts\Remove-LabVM.ps1 -Name WS25-VM03
.\scripts\New-WS2025LabVMs.ps1
```

`Remove-LabVM.ps1` deletes the VM, its disks and its folder, but never the template. `New-WS2025LabVMs.ps1` recreates only the missing VMs from the template.
