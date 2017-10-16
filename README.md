
# shotovuln

An offensive bash script which tries to find GENERIC privilege escalation or privilege changes vulnerabilities and similar issues on \*Nix systems. The tool will try to focus only on useful information. 

# target audience  

Pentesters which need accurate and useful information for privilege escalation 

the script follow this guidelines 
- non interactive shell 
- stealth, try not to touch drive except if needed, try to run everything in memory
- do not output useless information, only valid vuln or nothing
- run as low privilege user
- show clear path to root if it exists 
- no colors, can be used outside of standard terminals
- user should pipe output to file for better read
- try to document the vuln example in comments (ie CVE-xxx CWE weakness)
- requirement on the compromised box : \*nix OS, bash [+ python , pip: for bruteforce]

typical usage: you get a webshell on \*nix and you want to elevate


# args 

Usage: ./shotovuln.sh [currentpassword] [brute] [network] [nosuidaudit] [pupy] [msf]

# another audit script for Linux again ? seriously ? 

Yes and no. This is attack oriented. Alternative for this script (lynis, upc, ...) are outputing too much unecessary information or information which need to be cross checked. These step slows down pentesters in their tentative to escalate. This script also focuses on the cause of the vulnerability so it might find new ones. 
