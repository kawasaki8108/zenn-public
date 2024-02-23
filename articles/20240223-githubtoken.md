---
title: "GitHubのtoken(classic)を使った認証"
emoji: "👻"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GitHub,Windows]
published: true
---
# 背景
* PCはWindows 11（GitBashを使って連携するのが普段使い）
* 今回はWSL2-UbuntuのgitからもGitHub連携することにしました。
* 「[WSL2のUbuntuにZenn CLIを導入](https://zenn.dev/kawasaki8108/articles/20240221-beginzenn)」で`git push`まで難儀したのでそのメモを残します。

# 問題に遭遇するまでの経緯
要約すると、最初はIDとPassだけでできたのに次pushしたらエラー起きたということです。
1. zennと連携するためのリポジトリをGitHubに作成
2. Ubuntuのユーザーホームディレクトリに`git clone`
3. テストで`git push`（addやcommitは割愛）
   ![git1](/images/20240223-githubtoken/zenn015.png)
4. `user.email`と`user.name`を設定
5. 再度`git push`
6. 以下の通り求められるので、usernameとGitHubのパスワードを入力
   ```bash
   Username for 'https://github.com': kawasaki8108
   Password for 'https://kawasaki8108@github.com':GitHubのパスワード
   ```
7. 再度`git push`して問題なくpush完了。
8. 後のタイミングで改めて`git push`したら、またusernameとpassword求められて先ほどと同じように入力すると、以下の通り、認証方法が変わった旨のエラーが返されました。
   ```bash
   Username for 'https://github.com': kawasaki8108
   Password for 'https://kawasaki8108@github.com':GitHubのパスワード
   remote: Support for password authentication was removed on August 13, 2021.
   remote: Please see https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
   fatal: unable to access 'https://github.com/ユーザー名/リポジトリ名.git/'
   ```
調べると、トークンによる認証を求められているらしく、その設定をしていきます
# トークンの認証を設定する
上記のエラーメッセージで案内されているURL―[GitHubの公式](https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls)によると、パスワードを求められたらトークンを入力せよとのことでした。
> コマンドラインで HTTPS URL を使用してリモート リポジトリに 、、git clone、git fetchまたはgit pullを接続すると、Git は GitHub のユーザー名とパスワードを要求します。git pushGit でパスワードの入力を求められたら、個人のアクセス トークンを入力します。

公式のほかこちらの記事を参考に実施しました。
https://dev.classmethod.jp/articles/github-personal-access-tokens/
https://qiita.com/setonao/items/28749762c0bc1fbbf502
https://qiita.com/jun_aws/items/35599f54633582ae2086

テキストで流れをメモしておきます。
1. GitHubにログイン> [Settings] > [Developer settings] > [Personal access tokens]
2. [tokens (classic)]を選択し、Select scopeは、`repo`、`admin:repo_hook`、`delete_repo`、をonにして「Generate token」を押す
3. 発行されたトークンをコピー（一度しか表示されないので注意）
4. 毎回usernameとpasswordを聞かれないように認証情報を保存できるようにしておく。今回はstoreモードにしました。デフォルトでは「~/.git-credentials」に保存される。（セキュリティ的にはcacheとタイムアウト使うのがいいと思います）
   ```bash
   $ git config --global credential.helper store --file ~/.git-credentials
   ```
5. `git push`してユーザ名、発行したトークンを入力する（公式記載の通り`git pull`など、GitHub連携系のコマンドならok）
   ```bash
   $ git push
   Username for 'https://github.com':ユーザ名
   Password for 'https://xxx@github.com':発行したトークン
   ```
6. いちおう保存されているか`cat ~/.git-credentials`で確認。平文で記載されているはず。
7. 最終的にconfigは以下の通り
   ```bash
   $ git config -l
   user.email=メールアドレス
   user.name=kawasaki8108
   credential.helper=store
   core.repositoryformatversion=0
   core.filemode=true
   core.bare=false
   core.logallrefupdates=true
   remote.origin.url=https://github.com/kawasaki8108/zenn-public.git
   remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
   branch.main.remote=origin
   branch.main.merge=refs/heads/main
   credential.helper=store
   ```

# 感想
* 普段使いのGitBashの方でも沼ったので別途まとめておこうと思います。
* 今回のトークンはclassicにしましたが、「Fine-grained personal access tokens」の方がセキュアなのでbeta版ですがこちらを使った方がいいかと思います。
* Fine-grained tokenも実際試したのですが、上記の手順でうまく行かなかったので、permissionsが適切でなかったのか、勘違いしているだけなのか、また落ち着いて試してみます。
* Fine-grained tokenを試した時のPermissionsと成功されている参考記事を下に載せます。
  ![githubtoken](/images/20240223-githubtoken/githubtoken.png)

https://zenn.dev/b0b/articles/fine-grained-pat-usageb