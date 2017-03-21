#!/bin/bash
# v0.0

echo "SHOTOVULN SENSEiiii *0* show me the path to R00T *o* !!!" 
echo "Please run this script as low privilege user :]" 



echo -e "\n"
echo "### 1. Auditing features to go to other privileges" 

echo "What can you do as sudo, if you know your own password ofc :) ?" 
sudo -l 

echo "Now bruteforcing the loggedin user password" 
#while read mypass; do echo $my_pass | sudo -S id; done < wordlist.txt 

echo "Brute forcing local users via su, please download / compile sucrack"
./sucrack wordlist.txt 

echo "Scanning localhost port for SSH and other protocols" 
nc -z -v 127.0.0.1 1-22222 

echo "Do we have access to dmesg?" 
dmesg




echo -e "\n"
echo "### 2. Auditing file and folders permissions to privesc" 

echo "Root owned files in non root owned directory, ie. non root user can replace root owned files" 
for x in `find /var -type f -user root 2>/dev/null -exec dirname {} + | sort -u`; do (echo -n "$x is owned by " && stat -c %U $x) | grep -v 'root'; done

#echo "Checking tmp files for secrets" 
#find /tmp/ -type f -size +0 -exec ls -alh {} + 2>/dev/null 

echo "Writable folders for everyone, usefull for next steps" 
find / -type d -perm /o+w 2>/dev/null





echo -e "\n"
### https://www.pentestpartners.com/blog/exploiting-suid-executables/
echo "### 3. Auditing SUID and SUID operations in a dumb way ... ie no arguments provided to them." 

echo "SGID folders writable by others, ie. other can get group rights by writing to it" 
find / -type d -perm /g+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

echo "SUID folders writable by others, ie. other can get user rights by writing to it" 
find / -type d -perm /u+s -perm /o+w -exec ls -alhd {} + 2>/dev/null;

#echo "Test SUID conf files for error based info disclosure" 


echo "generating SUID logs ......" 
mkdir -p ~/.shotologs
for x in `find / -perm /4000 2>/dev/null`; do timeout 30s strace $x 2>~/.shotologs/`basename $x`.stracelog; done 

echo "Relative path opening in suid binaries, ie. can fool the suid binary to open arbitrary file" 
grep 'open("\.' ~/.shotologs/* --color 
grep 'open(' ~/.shotologs/* | grep -v 'open("/' 


echo "Environment variables used in suid binaries, ie. untrusted use of env variables" 
grep "getenv(" logs/* --color 

echo "Exec used in suid binaries, ie. untrusted use of PATH maybe" 
grep --color execve logs/*




echo -e "\n"
echo "### 4. Specific cases which enable you to change privilege" 

echo "Apache symlink test" 
find / -name apache2.conf 2>/dev/null


#echo "Perl or python env var" 





