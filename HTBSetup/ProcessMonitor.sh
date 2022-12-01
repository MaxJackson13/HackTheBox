# Tested on GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu). This script seems to be very picky about zsh vs sh vs bash
# This script is useful for finding any unknown processes executing on a schedule (cron, systemd timer, at etc.). Handy for CTFs but also 
# for finding malicious processes executing in the background 

#!/bin/bash
IFS=$'\t'                                   # Set internal field separator to tab. Newline would erase 'n' characters from the output! Not sure why?

old=$(ps -eo cmd | grep -Ev '\[.*\]')       # Get initial processes selecting only the command + args (-o cmd). Grep out [] processes
                                            # which are children of the internal kernel thread (ppid 2) to reduce noise
while true; do
  new=$(ps -eo cmd | grep -Ev '\[.*\]')     # Same as above 
  diff <(echo -e $old) <(echo -e $new)      # Diff old and new process lists to observe changes
  sleep 1                               
  old=$new                                   
done


############################################
#
# In the first terminal run 
#
# ┌──(kali㉿kali)-[~]
# └─$ bash ProcessMonitor.sh
#
# Then in the second start a new process, I chose netcat
#
# ┌──(kali㉿kali)-[~]
# └─$ nc -nvlp 7777
# listening on [any] 7777 ...
#
# And back in the first terminal we see
#
# ┌──(kali㉿kali)-[~]
# └─$ bash ProcessMonitor.sh
# 99d98
# < nc -nvlp 7777
