---
title: "Windows-GitBashからgit pushして403エラー"
emoji: "🕌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GitBash,Windows,GitHub,SSHkey]
published: true
---
# 背景
* Windows 11にGitBashを入れた構成
# エラー発生までの経緯
1. GitHubとの連携はusernameとpasswordの認証によってできていました
2. [別でWSL2-UbuntuからGitHub連携のためにトークン発行した](https://zenn.dev/kawasaki8108/articles/20240223-githubtoken)ので、そのトークンをコントロールパネルの資格情報マネージャーに入れ直しGitBashからもGitHub連携できるようにしました。
   ![manager](/images/20240224-gitbashssh/manager.png)
3. 挙動確認のために資格情報に入れたPWを変えてエラー内容確認し、もとのトークンに戻したら、403エラーに遭遇しました↓。
    ```bash
    $ git push
    remote: Permission to kawasaki8108/AmazonLinux-doc.git denied to kawasaki8108.
    fatal: unable to access 'https://github.com/kawasaki8108/AmazonLinux-doc.git/': The requested URL returned error: 403
    ```
4. （ちなみに資格情報マネージャーでPWに変更したら別のエラーになります↓。いわゆる認証方法トークンとかに変えてねということです。このあとトークンに戻しています）
    ```bash
    $ git push
    remote: Support for password authentication was removed on August 13, 2021.
    remote: Please see https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
    fatal: Authentication failed for 'https://github.com/kawasaki8108/AmazonLinux-doc.git/'
    ```
# 改めて現状把握
GitHub連携のための認証情報をどこで保持しているかを以下のコマンドで確認できます。
```bash
$ git config --show-origin credential.helper
file:C:/Program Files/Git/etc/gitconfig manager
```
やっぱりコンパネの資格情報マネージャーであっていそうです。
いちおう`git clone`や`git pull`できるか試してみる↓と、問題なくできたので、おそらくトークンが間違っていることはなさそうです。(リモートリポジトリはなんでもいいです)
```bash
$ git clone https://github.com/kawasaki8108/AmazonLinux-doc.git
Cloning into 'AmazonLinux-doc'...
remote: Enumerating objects: 60, done.
remote: Counting objects: 100% (60/60), done.
remote: Compressing objects: 100% (43/43), done.
Receiving objects:  41% (25/60)used 50 (delta 9), pack-reused 0
Receiving objects: 100% (60/60), 17.92 KiB | 8.96 MiB/s, done.
Resolving deltas: 100% (13/13), done.

$ cd AmazonLinux-doc/
# ユーザー名@DESKTOP-FV4SS4B MINGW64 ~/AWS/AmazonLinux-doc (main)
$ git pull
Already up to date.
```
念押しで保持しているトークン自体の文字列も確認し、あってました。
```bash
$ git credential fill   #対話モードになるので
protocol=https          #この行と
host=github.com         #この行を入力してエンター
                        #エンター
protocol=https          #この行以下が表示します
host=github.com
username=kawasaki8108
password=github_pat_11BA～～～～～～～  #このトークンも発行したもので、あっていました
```
設定が足りていないのだろうと思います。（いままで問題なかったのに何で新たに設定するの？という気持ちはぐっとこらえます）

# SSH接続
エラーメッセージ内容でググってみると同じような状況の記事を見つけられました。
そこで、トークン認証以外の方法を試している方の記事を参考にして、「SSHkey」を使ってSSH接続を試して`git push`を試みました。
参考記事）

https://www.virtual-surfer.com/entry/2018/04/13/190000
https://qiita.com/shizuma/items/2b2f873a0034839e47ce
https://learn.microsoft.com/ja-jp/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops
https://qiita.com/tatsunoshin/items/3d8b15fe50e85c918761
https://hal0taso.hateblo.jp/entry/git403error

わかりやすいようにユーザーホームディレクトリにある.sshに入り、公開鍵(id_rsa.pub)、秘密鍵(id_rsa)がまだないことを確認します。
```bash
$ cd                #ユーザーホームディレクトリに戻ります
$ ls -a | grep ssh  #.sshあること確認
.lesshst
.ssh/               #ある
$ cd .ssh
$ ls -a
./  ../  config  known_hosts  known_hosts.old  project_key  project_key.pub
#まだない↑。あったらこのあとで上書きされるでしょうから、念のためもあり現時点でbefore確認
```
鍵を生成していきます
```bash
$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/c/Users/ユーザー名/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /c/Users/ユーザー名/.ssh/id_rsa   #秘密鍵作られた
Your public key has been saved in /c/Users/ユーザー名/.ssh/id_rsa.pub   #公開鍵作られた
The key fingerprint is:
SHA256:MYck*************************************** ユーザー名@DESKTOP-FV4SS4B
The key's randomart image is:
+---[RSA 3072]----+
|      o.+o. .    |
|       =.. o .. .|
|       .= o =. + |
|      .  = = .o +|
|     .o.S . .. o.|
|   . ..=..  o E  |
|  o   + +o * .   |
| . +.= oo.+ *    |
|  o.o.*o . . .   |
+----[SHA256]-----+

$ clip < ~/.ssh/id_rsa.pub      #公開鍵をコピーします
```
GitHub上に公開鍵をセットします。(公式は[こちら](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account))
* [Settings] > [SSH and GPG keys] > 「SSH keys」のところで[New SSH key]ボタン押します。
* さっきコピーした公開鍵を貼り付けます。タイトルはなんでもok。
  ![github_pubkey](/images/20240224-gitbashssh/github_pubkey.png)
* 入力完了したら[Add SSH key]で登録完了↓。
  ![github_pubkey](/images/20240224-gitbashssh/github_pubkeyset.png)

GitHub（＝ホスト）にSSH接続するため、ホスト情報やその時使う鍵情報↓をconfigに登録します。AWS_EC2でいうところのキーペア使ってSSH接続するときのホスト情報を入れる感じです。
* [公式](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/using-ssh-agent-forwarding)のいうとおり、`ssh -T git@github.com`で接続確認するので、そのコマンドとつじつま合うようにしています↓。@の前はユーザー名、後ろはホスト名ということで。
* config内のどこでもokですが、すでに記述しているホスト情報等あれば一番下か上に追記することがわかりやすいと思います。
```
Host github github.com          #なんでもいい
    User git                    #@の前にいれる
    Port 22
    HostName github.com         #@の後ろにいれる
    IdentityFile ~/.ssh/id_rsa  #EC2へのSSH接続でいうところのkeypairの格納場所
```
設定できたので、テスト接続します。
```bash
$ ssh -T git@github.com
Hi kawasaki8108! You've successfully authenticated, but GitHub does not provide shell access.
```
公式に書いている通りのレスが来たので成功しました。
所定のリポジトリに`cd`して`git push`します。
```bash
$ git push
remote: Permission to kawasaki8108/AmazonLinux-doc.git denied to kawasaki8108.
fatal: unable to access 'https://github.com/kawasaki8108/AmazonLinux-doc.git/': The requested URL returned error: 403
```
何がだめなのか、、、
[公式](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/using-ssh-agent-forwarding)にも書いてありました。SSH用のURLでないとだめだと。
>```
>[remote "origin"]
>  url = git@github.com:YOUR_ACCOUNT/YOUR_PROJECT.git
>  fetch = +refs/heads/*:refs/remotes/origin/*
>```
> ![sshurl](/images/20240224-gitbashssh/githubssh.png)

現状確認してみると、、いつものURLです。。
```bash
$ git config remote.origin.url
https://github.com/kawasaki8108/AmazonLinux-doc.git
```
ということで、URLを設定しなおします。
```bash
$ git remote set-url origin git@github.com:kawasaki8108/AmazonLinux-doc.git
$ git config remote.origin.url
git@github.com:kawasaki8108/AmazonLinux-doc.git #設定できた
```
改めて`git push`します。
```bash
$ git push
Everything up-to-date
```
pushの必要性自体はないレスでしたが、エラーなくなったので解消完了です。

# まとめ
* いままでSSH接続をしなくても問題なくpushできていたのですが、何を機に403エラーとなったのかはわかりませんでした。
* GitHubへのSSH接続の流れがつかめました。
* SSHkey生成自体の理解は以下の記事を参考にしました。

https://dev.classmethod.jp/articles/ssh-keygen-tips/
https://qiita.com/labpixel/items/d3e850144117eda2f1bd
