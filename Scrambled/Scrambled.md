We'll first run a portscan against the target 10.10.11.168, here I'm using my bash alias `fscan`

`fscan 10.10.11.168`

<img src="Images/Ports.png" width=600>

We see all the typical open ports of a domain controller and the nmap scan reveal the FQDN of the domain controller: **dc1.scrm.local**

I'll add **scrm.local** and **dc1.scrm.local** to my `/etc/hosts` file

Usually I'd start with quickly checking for unauthenticated access to SMB or RPC using 
```
smbclient -N -L \\10.10.11.168
crackmapexec smb 10.10.11.168 -u '' -p ''
smbmap -H 10.10.11.168
rpcclient 10.10.11.168 -N
```
but all receieve <b>NT_STATUS_NOT_SUPPORTED</b> errors, the reason for which we discover upon navigating to the website

<img src="Images/NTLM.png" width=600>

It appears NTLM authentication has been disabled across the domain, so any authentications will have to use Kerberos.

Exploring the page further reveals a further two items of interest:

- We have a potential username of **ksimpson**

<img src="Images/KSimpson.png" width=600>

- Passwords are being reset as the username of the account

<img src="Images/PasswordReset.png" width=600>

From here we can do two things:

1. Use kerbrute to verify that ksimpson is in fact a domain user
2. Authenticate using kerberos to see if I can access any shares over SMB using the credentials ksimpson:ksimpson

I'll use `kerbrute` for the former and impacket's `smbclient.py` for the latter.

Kerbrute's userenum works by sending a request for a TGT, and if **UF_DONT_REQUIRE_PREAUTH** is not set for this user (which it usually isn't) the DC will respond with either

1. A PRINCIPAL UNKNOWN error and the username does not exist
2. Or the DC will prompt for pre-authentication, in which case the user exists in the domain

The command line for this looks like 

<img src="Images/Kerbrute.png" width=600>

and we see **ksimpson** is a valid username

Next we check `smb`

<img src="Images/smbclient.png" width=600>

