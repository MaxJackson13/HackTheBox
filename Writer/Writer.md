I'll start with a port scan using my alias `fscan` which launches a default script and version scan against the ports found from a full port scan.

<img src='Images/fscan.png'>

We see ssh on port 22, apache serving a website on port 80 and samba on 139/445. I'll quickly see what I can do over smb.

<img src='Images/smbmap.png'>

I don't have any access here. I'll revisit if I find some credentials.

<img src='Images/gobuster.png'>

Gobuster finds a directory called `administrative`. It leads to a login page 

<img src='Images/administrative.png'>

I'll test for SQL injection with the payload `admin'-- -`. This logs me in. I suspect the query is along the lines of 

`select * from users where username={username} and password=md5({password})`

so my injection malforms the query into

`select * from users where username=admin` 

which authenticates me as the user admin.

<img src='Images/script.png'>
