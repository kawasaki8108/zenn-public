---
title: "ローカルWSL2のAnsible-playbookでEC2にwebサーバーを導入"
emoji: "😸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [WSL,Ansible,playbook,Nginx,EC2]
published: false
---
# 前提
* コントロールノード：Windows11PC-WSL2-Ubuntu22.04LTSにAnsibleインストール済み
* コントロールノードの構成は以下の通り
  ```bash
  ansible-playbook/
  ├── files
  │   └── index.html
  ├── main.yml
  ```
* `ansible-galaxy init`などでベストプラクティスはまだ使っていません
* `/etc/ansible/hosts`ファイル内にEC2のパブリックIpv4を記入済み
* ターゲットノード：EC2（Amazon Linux2）
* キーペア（秘密鍵）はWinPCのCドライブ側に配置しているものを使います

# 目的
main.ymlに以下のタスクを入れてplaybook実行し、モジュールの使い方やファイルの変更し方を理解すること
* Nginxのインストール
* サービス有効化
* ファイル置き換えしてリスタート

# 結果
以下の通り記載のうえ、`sudo ansible-playbook main.yml`を実行し目的通りとなりました。
ターゲットノードへの影響具合を把握するためにもオプションを付けること推奨です。
* --syntax-check：構文上の問題がないことが確認できる
* --list-hosts：Playbook の影響を受けるホストを確認できる
* --diff：差分を確認できる 
* --check：ドライラン
```yml :main.yml
- hosts: EC2側のパブリックIP
  gather_facts: true
  remote_user: ec2-user
  become: yes             #権限昇格してsudo使えるようにする（noだとタスク1つ目からエラーとなる）
  vars:
      ansible_ssh_private_key_file: /mnt/c/Users/ユーザー名/キーペア名.pem
#今回入れた内容↓
  tasks:
    #Amazon Linux Extrasのトピックnginxを有効にする
    - name: Enable amzn2extra-nginx repository
      ansible.builtin.shell: amazon-linux-extras enable nginx1
      changed_when: false

    #/etc/yum.repos.d配下に入ったnginxのパッケージをインストール
    - name: Install Nginx packages from amazon-linux-extras
      ansible.builtin.yum:
        name: nginx
        state: present

    #ファイルの置き換え
    - name: Change nginx index.html page
      ansible.builtin.copy:
        src: index.html                         #置き換え元のファイル（files配下）
        dest: /usr/share/nginx/html/index.html  #置き換え先のフルパス
        backup: yes                             #置き換え先のバックアップを同じディレクトリで取得
      notify: restart nginx                     #下部のhandlersで定義した名前「restart nginx」

    #サービス有効化
    - name: nginx service activate
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
#設定ファイルなどに変更があったときだけ稼働させるものの定義（taskと同階層にhandlersを書く）
  handlers: 
    - name: restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

置き換えた後のページは以下の通りです。（抜粋）
<h2>のところです。このファイルを`/ansible-playbook/files/index.html`に格納しています。
```html :$ cat /ansible-playbook/files/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<h2>This page replaced on 3/4/2024. This sentence was inserted by h2.</h2>
<p>If you see this page, the nginx web server is successfully installed and
```

実際にはnginxインストール段階で1回playbook実行、サービス有効化の記述入れて2回目playbook実行、3回目ファイル置き換えと3段階に分けてやりました。
ターミナルの状況は以下展開して参照ください。
:::details 展開
```bash
20240303_20:15:30 kawasaki8108@DESKTOP-FV4SS4B:~/ansible-playbook
$ sudo ansible-playbook main.yml

PLAY [EC2側のパブリックIP] ***********************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform linux on host EC2側のパブリックIP is using the discovered Python
interpreter at /usr/bin/python3.7, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [EC2側のパブリックIP]

TASK [Enable amzn2extra-nginx repository] **********************************
ok: [EC2側のパブリックIP]

TASK [Install Nginx packages from amazon-linux-extras] *************************
changed: [EC2側のパブリックIP]

PLAY RECAP *********************************************************************
EC2側のパブリックIP              : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

20240303_20:15:54 kawasaki8108@DESKTOP-FV4SS4B:~/ansible-playbook
$ sudo ansible-playbook main.yml

PLAY [EC2側のパブリックIP] ***********************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform linux on host EC2側のパブリックIP is using the discovered Python
interpreter at /usr/bin/python3.7, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [EC2側のパブリックIP]

TASK [Enable amzn2extra-nginx repository] **********************************
ok: [EC2側のパブリックIP]

TASK [Install Nginx packages from amazon-linux-extras] *************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform linux on host EC2側のパブリックIP is using the discovered Python
interpreter at /usr/bin/python3.7, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [EC2側のパブリックIP]

TASK [Enable amzn2extra-nginx repository] **************************************
ok: [EC2側のパブリックIP]

TASK [Install Nginx packages from amazon-linux-extras] *************************
ok: [EC2側のパブリックIP]

TASK [nginx service activate] **************************************************
ok: [EC2側のパブリックIP]

PLAY RECAP *********************************************************************
EC2側のパブリックIP              : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

#以下はドライランの結果
$ sudo ansible-playbook main.yml --diff --check
[sudo] password for kawasaki8108: 

PLAY [54.199.169.46] *****************************************************************************

TASK [Gathering Facts] ***************************************************************************
[WARNING]: Platform linux on host 54.199.169.46 is using the discovered Python interpreter at
/usr/bin/python3.7, but future installation of another Python interpreter could change the
meaning of that path. See https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [54.199.169.46]

TASK [Enable amzn2extra-nginx repository] ********************************************************
skipping: [54.199.169.46]

TASK [Install Nginx packages from amazon-linux-extras] *******************************************
ok: [54.199.169.46]

TASK [Change nginx index.html page] **************************************************************
--- before: /usr/share/nginx/html/index.html
+++ after: /home/kawasaki8108/ansible-playbook/files/index.html
@@ -10,6 +10,7 @@
 </head>
 <body>
 <h1>Welcome to nginx!</h1>
+<h2>This page replaced on 3/4/2024. This sentence was inserted by h2.</h2>
 <p>If you see this page, the nginx web server is successfully installed and
 working. Further configuration is required.</p>


changed: [54.199.169.46]

TASK [nginx service activate] ********************************************************************
ok: [54.199.169.46]

PLAY RECAP ***************************************************************************************
54.199.169.46              : ok=4    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```
:::


▼nginxの起動確認
`$ curl http://127.0.0.1`(EC2側)でwelcomページの内容が返ってきましたので、成功です。
```html :http://127.0.0.1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<h2>This page replaced on 3/4/2024. This sentence was inserted by h2.</h2>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

![plybkwbsrvr](/images/20240302-plybkwbsrvr)

# main.ymlの詳細
### `ansible.builtin.`モジュールについて
* Ansibleをインストールしたときに含まれる標準モジュール
* 単に`shell`や`yum`などと記載しても問題なし
* 標準モジュールを利用していることが自明になるために記載いれています。あとは調べるとこの表記がメジャーです。
* ansible.builtin.モジュールの説明の参考
https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html
https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html#ansible-collections-ansible-builtin-dnf-module

### `changed_when: false`について
毎回実行されるようにしているので、この記述をなくすとchanged=1と返ってきます。
「え！？」と無駄に心配しちゃわないように、リポジトリを有効化したとしてもchangedの対象としないためにこの記述いれています。
```bash
TASK [Enable amzn2extra-nginx repository] ********************************************************
changed: [54.199.169.46]
```

### yumでnginxインストールする
/etc/yum.repos.d配下に入ったnginxのパッケージをインストールしています。
* Amazon Linux Extrasとyumの関係の参考
https://dev.classmethod.jp/articles/how-to-work-with-amazon-linux2-amazon-linux-extras/
:::details `/etc/yum.repos.d/amzn2-extras.repo`の中身を確認
```bash
$ cat /etc/yum.repos.d/amzn2-extras.repo
[amzn2extra-nginx1-source]
enabled = 0
name = Amazon Extras source repo for nginx1
mirrorlist = $awsproto://$amazonlinux.$awsregion.$awsdomain/$releasever/extras/nginx1/latest/SRPMS/mirror.list
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2
priority = 10
skip_if_unavailable = 1
report_instanceid = yes

[amzn2extra-nginx1-debuginfo]
enabled = 0
name = Amazon Extras debuginfo repo for nginx1
mirrorlist = $awsproto://$amazonlinux.$awsregion.$awsdomain/$releasever/extras/nginx1/latest/debuginfo/$basearch/mirror.list
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2
priority = 10
skip_if_unavailable = 1
report_instanceid = yes

[amzn2extra-nginx1]
enabled = 1
name = Amazon Extras repo for nginx1
mirrorlist = $awsproto://$amazonlinux.$awsregion.$awsdomain/$releasever/extras/nginx1/latest/$basearch/mirror.list
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2
priority = 10
skip_if_unavailable = 1
report_instanceid = yes
```

### `backup: yes`での既存ファイルバックアップ
* 中身に差分があれば既存ファイルをバックアップできる
* 変更なければbk発生しないし、playbook実行結果的にもchangedにはならない
* バックアップされたファイルはタイムスタンプ付き
```bash :EC2側での/usr/share/nginx/html内の確認結果
ls -al | grep index
-rw-r--r-- 1 root root  690 Mar  4 02:16 index.html
-rw-r--r-- 1 root root  615 Oct 13 22:35 index.html.20720.2024-03-04@01:51:55~
```
参考）
https://qiita.com/brighton0725/items/718a28462ca12ffb1831


### notifyとhandlersで設定変更を反映
* notify: とhandlers: を入れずに、サービス有効化のブロックで単に`state:restarted`するとplaybook実行ごとにchanged対象となってしまう
* notify: とhandlers: を入れると↑が回避できる。src:とdest:の2つのファイルの中身が違う場合にnotify:がトリガーされhandlers:が稼働する
https://www.youtube.com/watch?v=AlWUAij4quw
https://docs.ansible.com/ansible/2.9_ja/user_guide/playbooks_intro.html#handlers

# 参考
* 大筋は以下の2つを参考にしました
https://zenn.dev/endo/articles/f893ced432a9d2db8a5b
https://www.youtube.com/watch?v=ZFym0_qacz0

* タスクとモジュールの説明
> タスクが完了すべきジョブならば、モジュールはこのジョブを実際に完了するために必要なツールです。タスクは実行する必要があるアクションを定義し、モジュールはマネージドホスト上で実行されてこのアクションを達成し、終了時に戻り値を JSON 形式で収集します。
[（公式）Ansible モジュールの概要とその仕組み](https://www.redhat.com/ja/topics/automation/what-is-an-ansible-module)


* 自分のメモのためにデフォルトの`/etc/nginx/nginx.conf`の中身を貼っておきます
:::details 展開
```bash :/etc/nginx/nginx.conf
# For more information on configuration, see:       
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;    

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;      
    default_type        application/octet-stream;   

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;        

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;       
        location = /50x.html {
        }
    }

# Settings for a TLS enabled server.
#
#    server {
#        listen       443 ssl http2;
#        listen       [::]:443 ssl http2;
#        server_name  _;
#        root         /usr/share/nginx/html;        
#
#        ssl_certificate "/etc/pki/nginx/server.crt";
#        ssl_certificate_key "/etc/pki/nginx/private/server.key";
#        ssl_session_cache shared:SSL:1m;
#        ssl_session_timeout  10m;
#        ssl_ciphers PROFILE=SYSTEM;
#        ssl_prefer_server_ciphers on;
#
#        # Load configuration files for the default server block.
#        include /etc/nginx/default.d/*.conf;       
#
#        error_page 404 /404.html;
#            location = /40x.html {
#        }
#
#        error_page 500 502 503 504 /50x.html;      
#            location = /50x.html {
#        }
#    }

}
```
:::