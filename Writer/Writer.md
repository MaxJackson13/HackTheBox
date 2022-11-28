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

I'll revisit the sql injection to see what I can do here. I know the username parameter is injectable. I'll try the payload `test' union select 1,2,3,4,5,6` for the username and a random password. Intercepting the response in burpsuite I see `2` gets reflected back onto the webpage as `welcome 2`

<img src='Images/union.png'>

Next I'll try changing the 2 for `LOAD_FILE('/etc/passwd')` and I see the contents of `/etc/passwd` are returned so I have LFI.

<img src='Images/loadfile.png'>

I'll create a quick python script to send the injection payload including the specified file as the first argument of the script to the login page, parse out the file contents and save the file. I'll use mysql's `TO_BASE64()` function to return the base64 encoded file to avoid HTML entity encoding in the response HTML.

<img src='Images/script.png'>

I'll check the website configuration by including the file `/etc/apache2/sites-enabled/000-default.conf`

<img src='Images/sites-enabled.png'>

It shows the root of the website is `/var/www/writer.htb` and there's a `.wsgi` file which I'll check out. It also points to a development site on port `8080` only accessible through localhost. If a can find an SSRF I could interact with this site.

<img src='Images/wsgi.png'>

There's a comment about an `__init__.py` file which I'll read next. The exact location of the file is a bit ambiguous as `from writer import...` could mean a file `writer.py` or a parent directory `/writer`, but trying the path `/var/www/writer.htb/__init__.py` works. This file leaks some credentials:

<img src='Images/__init__.png'>

From `/etc/passwd` I saw the user `kyle`. I'll try the credentials `kyle:ToughPasswordToCrack` against smb.

<img src='Images/authsmbmap.png'>

The credentials work and grant me read/write access to the `writer2_project` share. I'll use `smbclient //10.10.11.101/writer2_project -u kyle -p ToughPasswordToCrack` to access the share. This is interesting as I could write a payload into the share and if I can cause it to execute on the server I'll have RCE. Listing the contents of the share shows 

<img src='Images/writer_proj.png'>

`writer_web/urls.py` contains

```
from django.conf.urls import url
from writer_web import views

urlpatterns = [
    url(r'^$', views.home_page, name='home'),
]
```

This says any URI will redirect to `/home` and load `views.home_page`. This file imports `view.py` which contains the `home_page` function

```
from django.shortcuts import render
from django.views.generic import TemplateView

def home_page(request):
    template_name = "index.html"
    return render(request,template_name)
```

so I can write a reverse shell into the `home_page` function and it will execute when I load any page on the site. Since 
