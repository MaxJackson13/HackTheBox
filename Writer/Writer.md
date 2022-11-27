I'll start with a port scan using my alias `fscan` which launches a default script and version scan against the ports found from a full port scan.

<img src='Images/fscan.png'>

We see ssh on port 22, apache serving a website on port 80 and samba on 139/445

<img src='Images/smbmap.png'>

I don't have any access here. I'll revisit if I find some credentials.

<img src='Images/gobuster.png'>

Gobuster finds a directory called `administrative`. It leads to a login page 

<img src='Images/administrative.png'>

<img src='Images/script.png'>
