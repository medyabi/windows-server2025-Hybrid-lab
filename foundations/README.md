# Level 100: Windows Server 2025 foundations

Five short labs for new presales engineers. You meet Windows Server 2025, learn how it's sold, and do the everyday admin tasks a customer expects you to know. No Azure, no domain: just your own server.

Why start here? Because every customer conversation starts with the basics. "Which edition do I need?", "How many licences for my three hosts?", "Can I manage it without a GUI?" If you can answer those calmly, the rest of the meeting goes well.

| Lab | What you'll be able to do | Time |
| --- | --- | --- |
| [1. Meet Windows Server 2025](100-01-meet-windows-server-2025.md) | Find the version, edition, activation and install type, and name the 2025 highlights | 30 min |
| [2. Editions and licensing](100-02-editions-and-licensing.md) | Pick the right edition and size a licence for a customer | 30 min |
| [3. Roles and features](100-03-roles-and-features.md) | Turn a server into a file server and a web server, in the GUI and in PowerShell | 30 min |
| [4. Manage and monitor your server](100-04-manage-and-monitor.md) | Use SConfig, PowerShell remoting, event logs and performance counters | 30 min |
| [5. Storage basics](100-05-storage-basics.md) | Add disks, compare NTFS and ReFS, and share a folder over SMB | 30 min |

About 2.5 hours in total: two lab slots.

**What you need:**

- Your lab VM: Windows Server 2025 Datacenter (Desktop Experience), with a user name and password from your lab admin.
- Remote Desktop. The connection steps are on the lab access page.
- Nothing else. No Azure subscription for this level.

> **Note:** your VM is reset to a clean state at the end of each slot, so you can't break anything for good. Experiment.

## The learning path

The Windows Server labs follow five levels. Each level answers a harder customer conversation.

| Level | Theme | After this level you can… |
| --- | --- | --- |
| **100** | Foundations (this track) | Explain Windows Server 2025, its editions and licensing, and do a 10-minute demo |
| **200** | [Hybrid management with Azure Arc](../README.md) | Run the Azure Arc and Software Assurance benefits demo end to end |
| **300** | Securing Windows Server | Answer "how do we secure our servers?" with proof |
| **400** | Windows Server HCI (coming) | Build a 2-node hyperconverged cluster and show it survive a failure |
| **500** | Architecture scenarios (coming) | Design a customer solution and check it against a self-assessment |

Start with [Lab 1: Meet Windows Server 2025](100-01-meet-windows-server-2025.md).
