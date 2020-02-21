#!/usr/bin/env python3


import os


hostname = os.environ['XP_h']
username = os.environ['XP_u']
password = os.environ['XP_p']


import base64
import paramiko
#key = paramiko.RSAKey(data=base64.b64decode(b'AAA...'))
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#client.get_host_keys().add('ssh.example.com', 'ssh-rsa', key)
client.connect(hostname,username=username,password=password)
stdin, stdout, stderr = client.exec_command('ls -al / && hostname -f && cat /etc/redhat-release')
for line in stdout:
    print('... ' + line.strip('\n'))
client.close()




print("OK")


