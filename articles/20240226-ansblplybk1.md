---
title: "WSL2からEC2にansible-playbookで小規模task実行"
emoji: "😸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [WSL,Ubuntu,EC2,Ansible,playbook]
published: true
---
# 目的
以下の構成でAnsibleのplaybookにより、簡単なTask実行テストをする
* コントロールノード：ローカルPC内のWSL2-Ubuntu
* 管理対象ノード：EC2（Amazon Linux2）
# 前提
* AnsibleはCドライブに格納しているキーペアの秘密鍵を使って接続
* [アドホックによる接続は完了済み](https://zenn.dev/kawasaki8108/articles/20240225-ansibleadhoc)
# 参考記事
* [Ansible入門講座#2 - Playbookを書く](https://www.youtube.com/watch?v=dS0rT9uSSS4&list=PL_RwLDGrI9OukEWiXyLWKxy-ccuBReL-o&index=2)
* [公式：Playbook の概要](https://docs.ansible.com/ansible/2.9_ja/user_guide/playbooks_intro.html#playbooks-intro)
* [公式：Connecting to hosts: behavioral inventory parameters](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#intro-inventory)

# 実施内容
実務で使用する場合、プロジェクトや実行環境（productやstage等）、によってフォルダ構成は考慮する必要あると思います。
今回はテストのため、とりあえずansible-playbookのフォルダ下にEC2側で処理実行されていることが小規模でわかる設定ファイルで試します。
### 1.playbook作成
```bash
$ cd ~
$ mkdir ansible-playbook && cd $_   #ansible-plyabook用のディレクトリ作ってその中に入ります
$ vim site.yml
```
vimでymlファイルに以下の内容を記述します。（エディタはなんでもok。YAMLの構文チェック系のプラグイン入っていると楽。）
ホスト名（IP）は`/etc/ansible/hosts`にも追記必要です。
```yml :site.yml
- hosts: EC2側のパブリックIP         #アドホック同様ホスト情報を記載
  gather_facts: true
  remote_user: ec2-user
  vars:
      ansible_ssh_private_key_file: /mnt/c/Users/ユーザー名/キーペア名.pem
      #公式のオプションに従って、場所指定しています。WSLからの実行なので、Cドライブ側にある秘密鍵の場所になります。

  tasks:
    - name: Make some folder
      file:                         #fileはフォルダ作成するモジュールです
        path: "~/test20240226"      #ec2-userのユーザーホームディレクトリにフォルダ作成します
        state: directory            #ディレクトリがある状態にするので、既存なら実行されませんが、あれば実行されます
```


## 2.playbook実行
`ansible-playbook 設定ファイル.yml`コマンドで実行できます。
成功結果を先に記載します。
```bash
#一回目
$ sudo ansible-playbook site.yml 

PLAY [52.196.13.185] *************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************
[WARNING]: Platform linux on host 52.196.13.185 is using the discovered Python interpreter at /usr/bin/python3.7, but future installation of another Python interpreter could change the
meaning of that path. See https://docs.ansible.com/ansible-core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [52.196.13.185]

TASK [Make some folder] **********************************************************************************************************************************************************************
changed: [52.196.13.185]

PLAY RECAP ***********************************************************************************************************************************************************************************
52.196.13.185              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

#二回目は「冪等性（べきとうせい）」の機能により、フォルダが既存なので実行されていません。ですのでchanged=0となっています。
$ sudo ansible-playbook site.yml

PLAY [52.196.13.185] *************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************
[WARNING]: Platform linux on host 52.196.13.185 is using the discovered Python interpreter at /usr/bin/python3.7, but future installation of another Python interpreter could change the      
meaning of that path. See https://docs.ansible.com/ansible-core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [52.196.13.185]

TASK [Make some folder] **********************************************************************************************************************************************************************
ok: [52.196.13.185]

PLAY RECAP ***********************************************************************************************************************************************************************************
52.196.13.185              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

失敗した経緯は以下に記載します。
:::details 展開
```bash
#真の一回目
$ ansible-playbook site.yml

PLAY [52.196.13.185] *************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************
The authenticity of host '52.196.13.185 (52.196.13.185)' can't be established.
ED25519 key fingerprint is SHA256:l+Ac***************************************
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:1: [hashed name]
    ~/.ssh/known_hosts:2: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
fatal: [52.196.13.185]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Warning: Permanently added '52.196.13.185' (ED25519) to the list of known hosts.\r\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\r\n@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @\r\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\r\nPermissions 0555 for '/mnt/c/Users/ユーザー名/キーペア名.pem' are too open.\r\nIt is required that your private key files are NOT accessible by others.\r\nThis private key will be ignored.\r\nLoad key \"/mnt/c/Users/ユーザー名/キーペア名.pem\": bad permissions\r\nec2-user@52.196.13.185: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).", "unreachable": true}

PLAY RECAP ***********************************************************************************************************************************************************************************
52.196.13.185              : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0
```
`Permission denied`と言われたのでsudoつけてやり直します。
```bash
$ sudo ansible-playbook site.yml
[sudo] password for kawasaki8108:

PLAY [52.196.13.185] *************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************
[WARNING]: Platform linux on host 52.196.13.185 is using the discovered Python interpreter at /usr/bin/python3.7, but future installation of another Python interpreter could change the
meaning of that path. See https://docs.ansible.com/ansible-core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [52.196.13.185]

TASK [Make some folder] **********************************************************************************************************************************************************************
fatal: [52.196.13.185]: FAILED! => {"changed": false, "msg": "value of state must be one of: absent, directory, file, hard, link, touch, got: directry"}

PLAY RECAP ***********************************************************************************************************************************************************************************
52.196.13.185              : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```
`fatal: [52.196.13.185]: FAILED! =>`のところで`got directry`と言われて`failed=1`となっているので、タイポしています。正しいスペルは上記の通りですが、ここでは誤記していました。
正しいスペルに直すと前述の成功結果のところで示す通りになります。
:::

EC2にSSHログインし、フォルダ生成されたことを確認します。
```bash
[ec2-user@ホスト名（privateIP） ~]$ pwd
/home/ec2-user
[ec2-user@ホスト名（privateIP） ~]$ ll | grep test
drwxrwxr-x 2 ec2-user ec2-user   6 Feb 26 10:46 test20240226
```

以上でplaybookによるテスト完了です。問題なく動いているみたいです。

# 感想
* 次からタスクを少しずつ増やしたり実用的なモジュール使ったりしていこうと思います。ミドルウェア（nginxやunicorn）なども入れていきたいので。
* この検証中、EC2へのSSH接続がよく切れるので、すぐ切れないように設定できたのが副産物です。（⇒詳細[こちら](https://zenn.dev/kawasaki8108/articles/20240226-sshtimeout)）

