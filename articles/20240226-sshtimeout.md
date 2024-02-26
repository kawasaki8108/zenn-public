---
title: "EC2へのssh接続がすぐ切れる問題解消"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GtiBash,ssh,EC2,]
published: false
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
sshd：ssh 用のデーモン・プログラムのこと

以上で設定完了です。

# 感想
* この設定のおかげで再接続する手間が省けました
* WSL2（Ubuntu）からもEC2に接続することがあるのですが、こちらの接続も切れなくなりました。
  なお、WSL2からのEC2接続時はWindowsのCドライブ > ユーザーホームディレクトリにあるキーペアを指定して接続しています。

