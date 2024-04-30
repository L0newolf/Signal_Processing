#!/usr/bin/env python
import pexpect
import struct, fcntl, os, sys, signal

def sigwinch_passthrough (sig, data):
    # Check for buggy platforms (see pexpect.setwinsize()).
    if 'TIOCGWINSZ' in dir(termios):
        TIOCGWINSZ = termios.TIOCGWINSZ
    else:
        TIOCGWINSZ = 1074295912 # assume
    s = struct.pack ("HHHH", 0, 0, 0, 0)
    a = struct.unpack ('HHHH', fcntl.ioctl(sys.stdout.fileno(), TIOCGWINSZ , s))
    global global_pexpect_instance
    global_pexpect_instance.setwinsize(a[0],a[1])

err = 0
daq = (["ssh root@192.168.0.10", "ssh root@192.168.0.11", "ssh root@192.168.0.12", "ssh root@192.168.0.13", "ssh root@192.168.10.10", "ssh root@192.168.10.11", "ssh root@192.168.10.12", "ssh root@192.168.10.13"])
count = 0
for count in range(0,8):
 ssh_newkey = 'Are you sure you want to continue connecting'
 p=pexpect.spawn(daq[count])
 i=p.expect([ssh_newkey,'password:',pexpect.EOF,pexpect.TIMEOUT],1)
 if i==0:
    p.sendline('yes')
    print "DAQ",(count+1),"Logged in"  
    #i=p.expect([ssh_newkey,'password:',pexpect.EOF])
 if i==1:
    print "I give password",
    p.sendline("root")
 elif i==2:
    print "I either got key or connection timeout"
    err = 1
    pass
 elif i==3: #timeout
    err = 1
    pass
 p.sendline("\r")
 global global_pexpect_instance
 global_pexpect_instance = p
 signal.signal(signal.SIGWINCH, sigwinch_passthrough)
else:
 if err != 0:
 	print 'WARNING: Some DAQ modules NOT logged-in'

 else:
	print 'DAQ modules log-in complete'

try:
    #p.interact()
    sys.exit(0)
except:
    sys.exit(1)
