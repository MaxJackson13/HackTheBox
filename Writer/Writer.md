I'll start with a port scan using my alias `fscan` which launches a default script and version scan against the ports found from a full port scan.

<img src='Images/fscan.png'>

We see ssh on port 22, apache serving a website on port 80 and samba on 139/445. I'll quickly see what I can do over smb.

<img src='Images/smbmap.png'>

I don't have any access here. I'll revisit if I find some credentials.

<img src='Images/gobuster.png'>

Gobuster finds a directory called `administrative`. It leads to a login page:

<img src='Images/administrative.png'>

I'll test for SQL injection with the payload `admin'-- -`. This logs me in. I suspect the query is along the lines of 

`select * from users where username={username} and password=md5({password})`

so my injection malforms the query into

`select * from users where username=admin` 

which authenticates me as the admin user. I'll come back and examine the injection further if need be.

I get redirected to `/dashboard`.

<img src='Images/dashboard.png'>

clicking around I find a `/stories` directory.

<img src='Images/stories.png'>

It has the option to upload a `.jpg` file from the local computer or to upload a file from a url. 

<img src='Images/storiesadd.png'>

I'll upload a `jpg` and intercept the request in burpsuite. I'll append `.php` to the filename, change the mimetype to `application/x-php` and append a simple command injection payload after the magic bytes.

<img src='Images/bugmodified.png'>

I can see the file has sucessfuly upload to the `/static/img` folder. 

<img src='Images/staticimg.png'>

Visiting the url `static/img/bug.jpg.php?cmd=id` returns an error however. It seems the webpage isn't configured to execute `php` despite the extension.

<img src='Images/fail.png'>

I'll revisit the sql injection to see what I can do here.


<img src='Images/script.png'>
