# Lightweight script to automate the low hanging fruit I first look for after compromising a linux host

C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
BLUE="${C}[1;34m"
YELLOW="${C}[1;33m"
NC="${C}[0m"

groups=$(groups)
name=$(whoami)

echo ""
echo "${YELLOW}Don't forget sudo -l like you always do!"

echo "";
echo -e "${GREEN}The following history files were found";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find / -type f -iname '.*history' -printf %M\ \ \ "user="%u\ \ \ %p\\n 2>/dev/null | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

echo "";
echo -e "${GREEN}The following world writable files were found";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";

find / -type f -perm -o+w 2>/dev/null -printf %M\ \ \ "user="%u\ \ \ %p\\n 2>/dev/null | grep -v 'run\|proc\|sys' | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
echo -e "${GREEN}The following SUID files were found";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find / -perm -4000 -printf %M\ \ \ "user="%u\ \ \ %p\\n 2>/dev/null | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
echo -e "${GREEN}The following SGID files were found";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find / -perm -2000 -printf %M\ \ \ "group="%g\ \ \ %p\\n 2>/dev/null | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
echo -e "${GREEN}You never know  what's inside /opt & /tmp";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find /opt /tmp -maxdepth 1 -printf %M\ \ \ "user="%g\ \ \ %p\\n 2>/dev/null | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
echo -e "${GREEN}Searching for non-system/non-application backups";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find / -type f \( -iname '*backup*' -o -iname '*.old' -o -iname '*.bak' -o -iname '*.swp' -o -iname '*.tmp' \) 2>/dev/null | grep -v '/usr/lib\|/var/lib\|/usr/share'
 -printf %M\ \ \ "user="%g\ \ \ %p\\n 2>/dev/null | sed -e "s/root/${RED}&${NC}/g" | sed -e "s/$name/${GREEN}&${NC}/g"

for g in $groups; 
do echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
echo "${GREEN}You're part of the $g group who owns these files";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";
find / -group $g -type f -printf %M\ \ %p\\n 2>/dev/null | grep -v "run\|sys\|proc\|$name";
done

echo -e "${BLUE}#############################################$NC";
echo "";
echo "${GREEN}Active connections:";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";

(netstat -antp | grep -i listen) 2>/dev/null | sed -e "s/127.0.0.1/${RED}&${NC}/g"
if [ $? -ne 0 ]; then
    ss -antl 2>/dev/null | sed -e "s/127.0.0.1/${RED}&${NC}/g"
        if [ $? -ne 0 ]; then
            echo 'No binary to enumerate active connections'
        fi
fi
echo ""
echo -e "${BLUE}#############################################$NC";
echo "";
echo "${GREEN}Examine file capabilities";
echo "";
echo -e "${BLUE}#############################################$NC";
echo "";

getcap -r / 2>/dev/null | sed -e "s/cap_setuid\|cap_setgid\|cap_chown\|cap_sys_admin\|cap_dac_override/${RED}&${NC}/g"




