---
title: "GitHubのtokenを使った認証"
emoji: "👻"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [GitHub,Windows]
published: false
---
# 背景
* PCはWindows 11で、GitBashを使って連携するのが普段使いです。
* UbuntuのgitからもGitHub連携することにしました。
* 「[WSL2のUbuntuにZenn CLIを導入](https://zenn.dev/kawasaki8108/articles/20240221-beginzenn)」で`git push`まで難儀したのでそのメモを残します。特にコントロールパネルに設定するところ。
# 問題に遭遇するまでの経緯
要約すると、最初はIDとPassだけで行けたのに次やったら
1. zennと連携するためのリポジトリをGitHubに作成
2. Ubuntuのユーザーホームディレクトリに`git clone`
3. テストで`git push`（addやcommitは割愛）
   ![git1](images/20240223-githubtoken/zenn015.png)
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
   remote: Please see https://github.blog/2020-07-30-token-authentication-requirements-for-api-and-git-operations/ for more information.
   fatal: unable to access 'https://github.com/ユーザー名/リポジトリ名.git/'
   ```

