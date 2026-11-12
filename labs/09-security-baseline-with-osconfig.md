# Lab 9: Security baseline with OSConfig (45 min)

[← Lab 8](08-windows-management-from-azure.md) · [Overview](../README.md) · [Cleanup and reset →](cleanup-and-reset.md)

In this lab you harden your server with **one command** and then prove it's compliant. It's the strongest answer to the customer question "how do we secure our servers?"

**What is OSConfig?** It's the security configuration engine built into Windows Server 2025. Microsoft ships ready-made **security baselines** — about 320 settings for a workgroup server — and OSConfig applies them, reports compliance, and keeps them from drifting. Think of it as a building inspector who doesn't just write a report, but also fixes the doors and comes back to check they stay locked.

Your VM isn't in a domain, so you use the **WorkgroupMember** baseline.

> **Read this before you start.** After the baseline, your Administrator password must be at least **14 characters**, the account **locks after 3 wrong passwords** for 15 minutes, and **copy-paste of files over RDP** is turned off. Type carefully.

### Steps

1. RDP to your VM and open **PowerShell as administrator**.
2. Take a "before" picture of a few settings, so you can compare later:

   ```
   Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol, RequireSecuritySignature
   Get-LocalUser Guest | Select-Object Name, Enabled
   Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard |
     Select-Object VirtualizationBasedSecurityStatus, SecurityServicesRunning
   ```
3. Install the OSConfig module (answer **Yes** to the NuGet prompt):

   ```
   Install-Module -Name Microsoft.OSConfig -Scope AllUsers -Force
   Get-Module -ListAvailable -Name Microsoft.OSConfig
   ```
4. Apply the baseline:

   ```
   Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember -Default
   ```
5. **Restart** the VM. When you sign back in, you're asked to change the Administrator password — use 14+ characters.
6. Check compliance. Every line shows a setting, its status, and the reason if it's not compliant:

   ```
   Get-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember |
     Format-Table Name, @{ Name = "Status"; Expression = { $_.Compliance.Status } },
                        @{ Name = "Reason"; Expression = { $_.Compliance.Reason } } -AutoSize -Wrap
   ```
7. Run the "before" commands from step 2 again. What changed? You should see SMB signing required, SMBv1 off and the Guest account disabled.
8. Customize one setting the supported way, and keep drift control on. For example, allow RDP drive redirection again:

   ```
   Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember -Name RemoteDesktopServicesDoNotAllowDriveRedirection -Value 0
   ```

   Restart to apply it.

**Close the loop with Azure.** Go back to **Policy** > **Compliance** from Lab 4. After the next evaluation (about 30 minutes), most of the rules that failed now pass — the same baseline, applied locally by OSConfig and reported centrally by Azure. Do the same in **Defender for Cloud** recommendations (Lab 7) and **Best Practices Assessment** (Lab 8).

### Check yourself

- Which five areas does the baseline cover? (Network exposure, credential theft, lateral movement, persistence and tampering, auditing.)
- What happens if an admin changes a baseline setting by hand? (OSConfig's **drift control** puts it back. To change a setting permanently, change it through OSConfig, like in step 8.)
- Why would you test the baseline before production? (TLS 1.2 minimum and SMB 3.0 minimum can break connections to old systems or old Linux SAMBA shares.)

### Customer talking points

- **Secure by default, in one command**: hundreds of Microsoft-recommended settings, no GPO project needed.
- **Drift control**: settings stay compliant even when someone changes them by hand.
- The same baselines can be **applied and reported at scale from Azure** with Azure Policy machine configuration on Arc-enabled servers — exactly what you set up in Lab 4.
- Built in to Windows Server 2025, no extra licence. A good reason to upgrade from 2016/2019.

---

[← Lab 8](08-windows-management-from-azure.md) · [Overview](../README.md) · [Cleanup and reset →](cleanup-and-reset.md)
