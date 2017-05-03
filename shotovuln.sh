#!/bin/bash

### COLORS
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
ORANGE='\033[93m'
NOCOLOR='\e[0m'

echo "SHOTOVULN v0.1"
# insert ASCII art =)
echo -e "$GREEN Senseiiii *0* show me the path to $RED R00T $BLUE *o* ! $NOCOLOR";
echo "";
echo "Please run this script as low privilege user :]";
echo -e "$ORANGE Usage: $NOCOLOR $0 $GREEN [currentuserpassword] [nonbrute] [nodwl]";
echo "";

# PHILOSOPHY / IDEAS
# - non interactive
# - stealth , try not to touch drive except if needed, try to run everything in memory as much as possible
# - do not output useless information
# - run as low privilege user
# - show clear path to root
# requirement on the compromised box : *nix OS, bash , python , pip


echo -e "$ORANGE### 0. Pre work and preparing $NOCOLOR";
echo " Saving writable folders for everyone, useful for next steps";
writabledirs=$(find / -type d -perm /o+w ! -path "*mqueue*" 2>/dev/null);
writedir=$(echo "$writabledirs" | head -n1);
echo -e "$NOCOLOR Will use as writable dir: $RED $writedir";

currentuser=$(id);
echo -e "$NOCOLOR Current user and privileges is: $RED $currentuser";
echo -e "$NOCOLOR Getting quality short password wordlist from internet...";
# TODO for dev purposes , test if file exists
if [ ! -f "$writedir/.wordlist" ]; then
wget -qO "$writedir/.wordlist" "https://raw.githubusercontent.com/berzerk0/Probable-Wordlists/master/Real-Passwords/Top220-probable.txt"; # 200 to be fast
passwords="$writedir/.wordlist";
fi;

echo " Getting valid users for login";
validusers=$(grep -v '/false' /etc/passwd | grep -v '/nologin' | cut -d ':' -f1);
# debug
echo "[debug] Valid users are:"
echo "$validusers";

# python and pip needed on the box TODO test here
# pip install pexpect;
# $pythonandpip=true | false






echo "";
echo -e "$ORANGE### 1. Auditing features-like paths to go to other privileges $NOCOLOR"
# sudo and su brute https://www.altsci.com/concepts/sudo-and-su-considered-harmful-sudosu-bruteforce-utility
if [ ! -z "$1" ] ; then
echo "Own / currentuser password provided!";
echo "What can you do as sudo with this password :] ?";
sudo -l;
else
echo "Now bruteforcing the loggedin user password through python script";
# TODO faster sudo bruteforcer , using python child / pexpect
# python tools/sudo_brute1.py < "$passwords" ; # here use a better script or smaller wordlist
fi;

echo "Brute forcing local users via su";
# python su brute script here

echo "Getting SSH permissions";
sshperm=$(grep -niR --color permit /etc/ssh/sshd_config);
echo "[debug] : $sshperm";

echo "Getting allow users if any in SSH config"
sshusers=$(grep -niR --color allowusers /etc/ssh/sshd_config);
echo "[debug]: $sshusers";

echo "Scanning localhost ports for SSH detection and brute force";
# TODO better ssh detection
nc -z -v 127.0.0.1 22;
nc -z -v 127.0.0.1 222;
nc -z -v 127.0.0.1 2222;
nc -z -v 127.0.0.1 22222;
nc -z -v 127.0.0.1 10022;

echo "Now bruting valid users on SSH ports using ssh passcript";
# ./tools/sshpassscript.sh "$passwords";

# TODO check if dmesg allows you to privesc echo "Do we have access to dmesg and check privesc related information ?"
#dmesg script;





echo "";
echo -e "$ORANGE### 2. Auditing file and folders permissions to privesc $NOCOLOR"

echo "Root owned files in non root owned directory, ie. other can replace root owned files"
for x in $(find /var -type f -user root 2>/dev/null -exec dirname {} + | sort -u); do (echo -n "$x is owned by " && stat -c %U "$x") | grep -v 'root'; done

echo "Writable directory in default PATH, ie. users can tamper PATH of SUID for instance"
pathtotest=$(echo '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' | tr ':' ' ');
#for x in pathtotest; do ; done

echo "Checking tmp files for passwords or secrets and storing them, i.e. other can use the password to elevate or test password reuse";
find /tmp/ -type f -size +0 -exec grep -i --color 'secret/|password/|' {} + 2>/dev/null;
# TODO this step outputs useless information sometimes so filter it better







echo "";
echo -e "$ORANGE### 3. Auditing SUID and SUID operations in a dumb way, no arguments provided to them.$NOCOLOR"
# TODO be careful not to kill network
### https://www.pentestpartners.com/blog/exploiting-suid-executables/;

echo "SGID folders writable by others, ie. other can get group rights by writing to it"
find / -type d -perm /g+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

echo "SUID folders writable by others, ie. other can get user rights by writing to it"
find / -type d -perm /u+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

echo "Test SUID conf files for error based info disclosure"
# TODO code it --conf / -c / grep conf in help
# example ./suidbinary -conf /etc/shadow outputs the user hashes

echo "Generating SUID logs ... you might receive some pop ups and error message since we are starting all SUID binaries.";
mkdir -p "$writedir/.shotologs";

find / -perm /4000 2>/dev/null | sort -u > "$writedir/.suidbinaries";
while read -r suid; do
echo "[debug $suid]";
basename=$(basename "$suid");
#sleep 6s;
# TODO bugfix here the script stops at the middle of the list
timeout 13s strace "$suid" 2>"$writedir"/.shotologs/"$basename".stracelog 1>/dev/null ;
done < "$writedir/.suidbinaries";
# do not move the bug from L140 - L146 because of crowdsource



# add this generic vuln , SUID root loading from writable dir :/
# https://www.exploit-db.com/exploits/41907/
echo "Relative path opening in suid binaries, ie. you can fool the suid binary to open arbitrary file."
grep -n 'open("\.' "$writedir"/.shotologs/* --color;
grep -n 'open(' "$writedir"/.shotologs/* | grep -v 'open("/';

echo "Environment variables used in suid binaries, ie. untrusted use of env variables."
grep -n --color "getenv(" "$writedir"/.shotologs/*;

echo "Exec used in suid binaries, ie. untrusted use of PATH potentialy."
grep -n --color 'execve(\.' "$writedir"/.shotologs/*;





echo "";
echo -e "$ORANGE### 4. Specific edge cases which enable you to change privilege. $NOCOLOR"

echo "Apache symlink test, i.e. this allows you to check other users files and folders using the shared apache user";
find / -name apache*.conf -exec echo {} + -exec grep -i symlink --color {} + 2>/dev/null;

echo "Pythonpath or environment var issues, i.e."
python -c "import sys; print '\n'.join(sys.path);"







echo "";
echo -e "$ORANGE### 5. Init.d script auditing $NOCOLOR";
### The problem is service (init.d) strips all environment variables but TERM, PATH and LANG which is a good thing
echo "RC scripts pointing to a user controled directory, i.e. user can write to it and get privilege";
#grep -n --color '/' /etc/rc.local;
echo "Init.d scripts using unfiltered environment variablesm, i.e. user can inject into it and get privilege";
grep -n -R -v 'PATH=\|LANG=\|TERM=' /etc/init.d/* | grep --color "PATH\|LANG\|TERM";
# TODO confirm this is exploitable , better regexp , remove commented line
# race PATH inject before init.d is starting
# init.d is starting early
echo "Usage of predictable or fixed files in a writable folder used by init.d";
# TODO list all path used by init, filter writable ones
usedbyinit="$(grep -n -R --color ' /tmp' /etc/init.d/* | sort -u)";
# regex select only path
# TODO crosscheck with writabledirs





echo "";
echo -e "$ORANGE### 6. Conf files password disclosure and password reuse $NOCOLOR";
echo "Checking passwords used in .conf files";
find / -name "*.conf" 2>/dev/null -exec grep -i --color "password =\|password=\|password :\|password:" {} +;
# TODO filter false positives, filter comments





echo "";
echo -e "$ORANGE### 7. Log file information disclosure $NOCOLOR";

echo "Valid users history files harvesting info";
historyfiles={1,2};
# $validusers history grepping




echo "";
echo -e "$ORANGE### X. Privesc matrix $NOCOLOR";
# we might need to create a matrix of user privs
# user1 > user2 > user9 > group1 > rootgroup > root
# BIG TODO , map the privilege , ie like user1 > user2 > user3 > root
# privescpath=(user1,user2);(user2,root)
