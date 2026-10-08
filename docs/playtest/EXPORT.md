# Owner's Godot export

Open the current project and use Project → Export → **Android Debug**. Export the APK using your working Godot Android setup. The preset uses the existing package `com.gabebartolo.idlerpg`, ARM64, portrait presentation, version code 3 and Internet permission for guild play. It excludes service code, tests, tools, development art and documentation from the game package. The desktop SDK is not being installed by this agent.

Keep the same signing key as your existing installed build. If Android rejects an update, preserve the installation and save while investigating the key or version code. Increase the version code for subsequent exports. If a phone is not ARM64, it needs a compatible architecture export.

Record the exact source commit and compute the APK SHA-256, for example with PowerShell `Get-FileHash -Algorithm SHA256 -LiteralPath '<your APK path>'`. Complete EVIDENCE.md on a real phone before distributing broadly.

Guild play needs a separately deployed reachable HTTPS service. Set its address in More → Guild → Connection. A successful APK export does not establish that the service is reachable or that device play has been checked.
