---
title: "Windows-GitBashからpushして403エラー"
emoji: "🕌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GitBash,Windows,GitHub,SSHkey]
published: false
---
# 背景
* Windows 11にGitBashを入れた構成
# エラー発生までの経緯
1. GitHubとの連携はusernameとpasswordの認証によってできていました
2. 別でWSL2-UbuntuからGitHub連携のためにトークン発行したので、そのトークンをコントロールパネルの資格情報に入れ直しGitBashからもGitHub連携できるようにしました。
3. 挙動確認のために資格情報に入れたPWを変えてエラー内容確認し、もとのトークンに戻したら、403エラーに遭遇しました↓。
    ```bash
    $ git push
    remote: Permission to kawasaki8108/AmazonLinux-doc.git denied to kawasaki8108.
    fatal: unable to access 'https://github.com/kawasaki8108/AmazonLinux-doc.git/': The requested URL returned error: 403
    ```
4. （ちなみに資格情報をPWに変更したら別のエラーになります↓。いわゆる認証方法トークンとかに変えてねということです。）
    ```bash
    $ git push
    remote: Support for password authentication was removed on August 13, 2021.
    remote: Please see https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
    fatal: Authentication failed for 'https://github.com/kawasaki8108/AmazonLinux-doc.git/'
    ```


