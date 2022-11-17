We'll first run a portscan against the target 10.10.11.168, here I'm using my bash alias `fscan`

`fscan 10.10.11.168`

<img src="Images/Ports.png" width=600>

We see all the typical open ports of a domain controller and the nmap scan reveal the FQDN of the domain controller: **dc1.scrm.local**

Usually I'd start with quickly checking for unauthenticated access to SMB or RPC using 
```
smbclient -N -L \\10.10.11.168
crackmapexec smb 10.10.11.168 -u '' -p ''
smbmap -H 10.10.11.168
rpcclient 10.10.11.168 -N
```
but all receieve <b>NT_STATUS_NOT_SUPPORTED</b> errors, the reason for we we discover upon navigating to the website

<img src="Images/NTLM.png" width=600>

It appears NTLM authentication has been disabled across the domain, so any authentications will have to use Kerberos.

Exploring the page further reveals a further two items of interest:

- We have a potential username of **ksimpson**

<img src="Images/KSimpson.png" width=600>

- Passwords are being reset as the username of the account

<img src="Images/PasswordReset.png" width=600>
