---
title: "EC2へのssh接続がすぐ切れる問題解消"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GitBash,ssh,EC2,]
published: true
---
# 背景
接続元：WindowsPCのターミナル（GitBashを使用）
接続先：AWS_EC2（Amazon Linux2）
状況：GitBashからsshコマンド打ち、EC2に接続しても何も触らず２分くらいしたら接続が切れる

# 目的
ssh接続がすぎ途切れないようにする。
ちなみに、VScodeの拡張機能Remote SSHを使えば途切れないのですが、サーバー負荷の問題もあるので別途考慮必要そうです↓
参考）[Visual Studio CodeでのSSH接続により、EC2サーバーが高負荷になり動かなくなった](https://tech.excite.co.jp/entry/2022/09/27/153341)

# 参考記事
https://zenn.dev/syommy_program/articles/c7bd0d0daa156c
こちらの記事の通りで解消しました。

# 実施内容メモ
### sshクライアント側の設定
今回のクライアントはローカルPCのユーザーホームディレクトリにある.sshの中身を設定します。
configファイル内に以下の記述を入れていきます。
```
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 5
```
以下が手順です。
```bash
$ pwd
/c/Users/kawasaki8
$ cd .ssh
$ ls -a
./  ../  config  id_rsa  id_rsa.pub  known_hosts  known_hosts.old  project_key  project_key.pub
$ cat config | grep ServerAlive
#(何もない)
$ vim config                    #記述を挿入して保存(:wq)
$ cat config | grep ServerAlive #編集前にコピーとってdiffで変更点確認する方がスマートと思いました
        ServerAliveInterval 60
        ServerAliveCountMax 5
```

### sshホスト側の設定
`/etc/ssh/sshd_config`の中身を変更します。
以下の記述を入れます。
```
ClientAliveInterval 60      #60秒おきにサーバーからの応答を確認
ClientAliveCountMax 120     #サーバーからの応答を120回待つ（⇒二時間）
```
以下手順です。
```bash
$ sudo cat /etc/ssh/sshd_config | grep Client
#ClientAliveInterval 0
#ClientAliveCountMax 3
$ sudo vim /etc/ssh/sshd_config
（中略）
$ sudo cat /etc/ssh/sshd_config | grep Client
ClientAliveInterval 60  
ClientAliveCountMax 120
sudo systemctl restart sshd     #sshdを再起動して設定を反映させます
```
:::details /etc/ssh/sshd_configの全文（「# 」部分は見出し化してしまうので一部修正）
#$OpenBSD: sshd_config,v 1.100 2016/08/15 12:32:04 naddy Exp $

#This is the sshd server system-wide configuration file.  See
#sshd_config(5) for more information.

#This sshd was compiled with PATH=/usr/local/bin:/usr/bin

#The strategy used for options in the default sshd_config shipped with
#OpenSSH is to specify options with their default value where
#possible, but leave them commented.  Uncommented options override the
#default value.

#If you want to change the port on a SELinux system, you have to tell
#SELinux about this change.
#semanage port -a -t ssh_port_t -p tcp #PORTNUMBER

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

#Ciphers and keying
#RekeyLimit default none

#Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

#Authentication:

#LoginGraceTime 2m
#PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

#The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
#but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile .ssh/authorized_keys

#AuthorizedPrincipalsFile none


#For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
#Change to yes if you don't trust ~/.ssh/known_hosts for
#HostbasedAuthentication
#IgnoreUserKnownHosts no
#Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

#To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no
PasswordAuthentication no

#Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

#Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

#GSSAPI options
GSSAPIAuthentication yes
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

#Set this to 'yes' to enable PAM authentication, account processing,
#and session processing. If this is enabled, PAM authentication will
#be allowed through the ChallengeResponseAuthentication and
#PasswordAuthentication.  Depending on your PAM configuration,
#PAM authentication via ChallengeResponseAuthentication may bypass
#the setting of "PermitRootLogin without-password".
#If you just want the PAM account and session checks to run without
#PAM authentication, then enable this but set PasswordAuthentication
#and ChallengeResponseAuthentication to 'no'.
#WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
#problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
#UsePrivilegeSeparation sandbox
#PermitUserEnvironment no
#Compression delayed
ClientAliveInterval 60
ClientAliveCountMax 120
#ShowPatchLevel no
#UseDNS yes
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

#no default banner path
#Banner none

#Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

#override default of no subsystems
Subsystem sftp  /usr/libexec/openssh/sftp-server

#Example of overriding settings on a per-user basis
#Match User anoncvs
#X11Forwarding no
#AllowTcpForwarding no
#PermitTTY no
#ForceCommand cvs server

AuthorizedKeysCommand /opt/aws/bin/eic_run_authorized_keys %u %f
AuthorizedKeysCommandUser ec2-instance-connect
:::

sshd：ssh 用のデーモン・プログラムのこと

以上で設定完了です。

# 感想
* この設定のおかげで再接続する手間が省けました。
* WSL2（Ubuntu）からもEC2に接続することがあるのですが、こちらの接続も切れなくなりました。
  なお、WSL2からのEC2接続時はWindowsのCドライブ > ユーザーホームディレクトリにあるキーペアを指定して接続しています。

