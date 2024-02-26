---
title: "WSL2-UbuntuのAnsibleからEC2に接続テスト"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [Ansible,WSL,Ubuntu,AWS,EC2]
published: true
---
# 背景
* Windows 11
* WSL2のディストリビューション：Ubuntu-22.04
* ローカルのUbuntu、EC2（Amazon Linux2）にAnsibleを動かすためのPythonは導入済み
* UbuntuにAnsible導入済み（[公式](https://docs.ansible.com/ansible/2.9_ja/installation_guide/intro_installation.html)参照）
# 目的
* ローカルUbuntuのAnsibleからアドホックコマンドでEC2へコマンドをなげられるか確認する
* 最終的にはplaybookによりいろいろ実行したいですが、今回は一旦ここまで
# 結論
今回は単純ですので、結論だけメモします。本題はplaybookですので。
### 1. `/etc/ansible/hosts`にホスト名（EC2のパブリックIpv4）を追記して保存
どこに記載してもいいですが、自分の場合は、最下部に（例）`35.78.170.81`と追記しました。
### 2. アドホックコマンド実行
3つ試してみて、意図した返答だったので問題なく接続・実行できたことが確認できました。
1つ目：pingによる疎通確認
2つ目、3つ目：コマンド実行
秘密鍵の置き場所がホストOS（Cドライブ）側なので、`/mnt/c/`からのディレクトリ指定しています。
```bash
$ sudo ansible EC2側のパブリックIP -m ping -u ec2-user --private-key=/mnt/c/Users/ユーザー名/キーペア名.pem
[WARNING]: Platform linux on host EC2側のパブリックIP is using the discovered Python interpreter at
/usr/bin/python3.7, but future installation of another Python interpreter could change the   
meaning of that path. See https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
EC2側のパブリックIP | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.7"
    },
    "changed": false,
    "ping": "pong"
}

#`echo test`コマンドを投げて`test`と返ってきています。
$ sudo ansible EC2側のパブリックIP -a "echo test" --extra-vars "ansible_user=ec2-user ansible_ssh_pr
ivate_key_file=/mnt/c/Users/ユーザー名/キーペア名.pem"
（中略）
EC2側のパブリックIP | CHANGED | rc=0 >>
test

#`python3 --version`コマンドを投げるとverが返ってきます。
$ sudo ansible EC2側のパブリックIP -a 'python3 --version' -u ec2-user --key-file=/mnt/c/Users/ユーザー名/キーペア名.pem
（中略）
EC2側のパブリックIP | CHANGED | rc=0 >>
Python 3.7.16
```
# 参考
* アドホックコマンドのやり方

https://docs.ansible.com/ansible/latest/command_guide/intro_adhoc.html
* ホストへの接続時のオプション（`--extra-vars "～～～～"`）

https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#intro-inventory
https://www.youtube.com/watch?v=LKSWE_endX8
https://docs.ansible.com/ansible/2.9/user_guide/modules.html#working-with-modules
https://oji-cloud.net/2022/07/25/post-7084/
https://qiita.com/yumenomatayume/items/552b1a4406e85df306c4

* アドホックコマンドエラーしたときのansibleからの案内
:::details 展開
```
usage: ansible [-h] [--version] [-v] [-b] [--become-method BECOME_METHOD]
               [--become-user BECOME_USER]
               [-K | --become-password-file BECOME_PASSWORD_FILE] [-i INVENTORY]
               [--list-hosts] [-l SUBSET] [-P POLL_INTERVAL] [-B SECONDS] [-o] [-t TREE]     
               [--private-key PRIVATE_KEY_FILE] [-u REMOTE_USER] [-c CONNECTION]
               [-T TIMEOUT] [--ssh-common-args SSH_COMMON_ARGS]
               [--sftp-extra-args SFTP_EXTRA_ARGS] [--scp-extra-args SCP_EXTRA_ARGS]
               [--ssh-extra-args SSH_EXTRA_ARGS]
               [-k | --connection-password-file CONNECTION_PASSWORD_FILE] [-C] [-D]
               [-e EXTRA_VARS] [--vault-id VAULT_IDS]
               [--ask-vault-password | --vault-password-file VAULT_PASSWORD_FILES]
               [-f FORKS] [-M MODULE_PATH] [--playbook-dir BASEDIR]
               [--task-timeout TASK_TIMEOUT] [-a MODULE_ARGS] [-m MODULE_NAME]
               pattern

Define and run a single task 'playbook' against a set of hosts

positional arguments:
  pattern               host pattern

options:
  --ask-vault-password, --ask-vault-pass
                        ask for vault password
  --become-password-file BECOME_PASSWORD_FILE, --become-pass-file BECOME_PASSWORD_FILE       
                        Become password file
  --connection-password-file CONNECTION_PASSWORD_FILE, --conn-pass-file CONNECTION_PASSWORD_FILE
                        Connection password file
  --list-hosts          outputs a list of matching hosts; does not execute anything else     
  --playbook-dir BASEDIR
                        Since this tool does not use playbooks, use this as a substitute     
                        playbook directory. This sets the relative path for many features    
                        including roles/ group_vars/ etc.
  --task-timeout TASK_TIMEOUT
                        set task timeout limit in seconds, must be positive integer.
  --vault-id VAULT_IDS  the vault identity to use
  --vault-password-file VAULT_PASSWORD_FILES, --vault-pass-file VAULT_PASSWORD_FILES
                        vault password file
  --version             show program's version number, config file location, configured      
                        module search path, module location, executable location and exit    
  -B SECONDS, --background SECONDS
                        run asynchronously, failing after X seconds (default=N/A)
  -C, --check           don't make any changes; instead, try to predict some of the changes  
                        that may occur
  -D, --diff            when changing (small) files and templates, show the differences in   
                        those files; works great with --check
  -K, --ask-become-pass
                        ask for privilege escalation password
  -M MODULE_PATH, --module-path MODULE_PATH
                        prepend colon-separated path(s) to module library (default={{        
                        ANSIBLE_HOME ~
                        "/plugins/modules:/usr/share/ansible/plugins/modules" }})
  -P POLL_INTERVAL, --poll POLL_INTERVAL
                        set the poll interval if using -B (default=15)
  -a MODULE_ARGS, --args MODULE_ARGS
                        The action's options in space separated k=v format: -a 'opt1=val1    
                        opt2=val2' or a json string: -a '{"opt1": "val1", "opt2": "val2"}'   
  -e EXTRA_VARS, --extra-vars EXTRA_VARS
                        set additional variables as key=value or YAML/JSON, if filename      
                        prepend with @
  -f FORKS, --forks FORKS
                        specify number of parallel processes to use (default=5)
  -h, --help            show this help message and exit
  -i INVENTORY, --inventory INVENTORY, --inventory-file INVENTORY
                        specify inventory host path or comma separated host list.
                        --inventory-file is deprecated
  -k, --ask-pass        ask for connection password
  -l SUBSET, --limit SUBSET
                        further limit selected hosts to an additional pattern
  -m MODULE_NAME, --module-name MODULE_NAME
                        Name of the action to execute (default=command)
  -o, --one-line        condense output
  -t TREE, --tree TREE  log output to this directory
  -v, --verbose         Causes Ansible to print more debug messages. Adding multiple -v      
                        will increase the verbosity, the builtin plugins currently evaluate  
                        up to -vvvvvv. A reasonable level to start is -vvv, connection       
                        debugging might require -vvvv.

Privilege Escalation Options:
  control how and which user you become as on target hosts

  --become-method BECOME_METHOD
                        privilege escalation method to use (default=sudo), use `ansible-doc  
                        -t become -l` to list valid choices.
  --become-user BECOME_USER
                        run operations as this user (default=root)
  -b, --become          run operations with become (does not imply password prompting)       

Connection Options:
  control as whom and how to connect to hosts

  --private-key PRIVATE_KEY_FILE, --key-file PRIVATE_KEY_FILE
                        use this file to authenticate the connection
  --scp-extra-args SCP_EXTRA_ARGS
                        specify extra arguments to pass to scp only (e.g. -l)
  --sftp-extra-args SFTP_EXTRA_ARGS
                        specify extra arguments to pass to sftp only (e.g. -f, -l)
  --ssh-common-args SSH_COMMON_ARGS
                        specify common arguments to pass to sftp/scp/ssh (e.g.
                        ProxyCommand)
  --ssh-extra-args SSH_EXTRA_ARGS
                        specify extra arguments to pass to ssh only (e.g. -R)
  -T TIMEOUT, --timeout TIMEOUT
                        override the connection timeout in seconds (default=10)
  -c CONNECTION, --connection CONNECTION
                        connection type to use (default=smart)
  -u REMOTE_USER, --user REMOTE_USER
                        connect as this user (default=None)

Some actions do not make sense in Ad-Hoc (include, meta, etc)
```
:::

# 感想
* アドホックでEC2への接続ができました。
* 次はplaybookを使っていくつかのタスクを実行したいと思います。
* 最終的に、AnsibleはCI/CD(CircleCI)パイプラインの1つとして、実行したいと思っています。
* この場合、CircleCIで呼び出した、CircleCI上のAnsibleは秘密鍵をどこで認識するのかの疑問がでました。
* [公式](https://circleci.com/docs/ja/add-ssh-key/)見る感じ、ローカルにおいてる秘密鍵ではなく、CircleCI上に保管するのかなと思いました。
