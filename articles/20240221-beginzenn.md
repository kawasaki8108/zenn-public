---
title: "WSL2のUbuntuにZenn CLIを導入"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [Ubuntu,Zenn CLI,nvm,npm,node]
published: true
---
# 環境
WindowsPCでLinux環境用意していろいろしてメモもしたいので、いっそこの環境上でZenn CLIを入れます。
* 仮想環境：WSL2
* WSLのディストリビューション：Ubuntu-22.04
* ホストのOS：Windows
  * エディション：Windows 11 Pro
  * バージョン：22H2
  * OS ビルド：22621.3155
  * プロセッサ：AMD Ryzen 5 7530U with Radeon Graphics 2.00 GHz
  * RAM：16GB

# 背景
* ローカルPCのAnsibleを使ってAWSのEC2に各種ソフトを導入したい（最終目標）
* Windowsは無理なのでLinux環境がいる（済）
* WSL、Ubuntu入れるまでつまづいた（済）
* 先は長そうなのでいろいろメモしておきたい、せっかくなのでGithub連携してZennを使おう（GitHubリポジトリ連携済み）
* WSLにZenn CLIいれようとするけど、つまづいてる、それをメモしておこ（今ココ）

# その他の前提
* GitHub側にWSL2用のリポジトリを用意し、ローカル(WSL2)との連携済

# 参考資料
* 基本のやり方（公式）
  * [GitHubリポジトリでZennのコンテンツを管理する](https://zenn.dev/zenn/articles/connect-to-github)
  * [Zenn CLIをインストールする](https://zenn.dev/zenn/articles/install-zenn-cli#1.-cli%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8B)
* つまづいたときの参照先
  * [Zenn CLI導入でつまづいたことメモ](https://zenn.dev/yutarom/articles/0c320a14163b7e)
  * [Zenn CLI の導入で躓いたところを書き残す](https://zenn.dev/dai_otsuka/articles/f293ec144fe0bf)
  * [Ubuntu に Node.js をインストールし、npm を最新バージョンに更新する方法](https://www.freecodecamp.org/japanese/news/how-to-install-node-js-on-ubuntu-and-update-npm-to-the-latest-version/)
  * https://github.com/nvm-sh/nvm#installing-and-updating
* 後で気づいた正攻法ぽいやり方
  * [Setup Zenn CLI on Ubuntu 22.04](https://zenn.dev/superdaigo/articles/setup-zenn-cli-environment-f92892a229bd90)
  * [WSL2 (Ubuntu20.04) に Zenn 執筆環境構築を構築してみた](https://zenn.dev/hrtkzi/articles/c1757e88f152ad)

# 実施したこと
とりあえずnpmがいるのねてことで、何も考えず以下実行。
```
$ sudo apt install npm
```

インストール確認してさっそく公式通りの基本のやり方で順に実施すると、`npx zenn init`で以下のエラーが返されました。そしてarticlesフォルダやbooksフォルダも生成されませんでした。
```
～～～～～～
～～～～～～
SyntaxError: Unexpected token '?'
```
参考記事の通り、npmのバージョンが古すぎるためでした。メモできていないのですが、バージョン8系でした。。<br>
一旦nodeやnpmを根こそぎ削除するところからやりました↓。（もっといいやり方あるはず。。）
```bash
sudo rm -rf /usr/bin/npm /usr/share/node* /usr/share/npm /usr/share/man/man1/node* /usr/share/man/man1/npm* /usr/include/node* /usr/include/npm
```
参考記事のとおり、nvmから導入することにしました。ちなみにyarnからでもいいかなと思います（参考：[yarnでzenn-cli導入する](https://zenn.dev/luna_chevalier/articles/56dcac1f1f8709d433a3)）。
```bash
$ cd ~ #一旦ホームディレクトリに戻りました
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 16555  100 16555    0     0  47169      0 --:--:-- --:--:-- --:--:-- 47165
=> Downloading nvm from git to '/home/kawasaki8108/.nvm'
=> Cloning into '/home/kawasaki8108/.nvm'...
remote: Enumerating objects: 365, done.
remote: Counting objects: 100% (365/365), done.
remote: Compressing objects: 100% (312/312), done.
remote: Total 365 (delta 43), reused 167 (delta 27), pack-reused 0
Receiving objects: 100% (365/365), 365.15 KiB | 1.32 MiB/s, done.
Resolving deltas: 100% (43/43), done.
* (HEAD detached at FETCH_HEAD)
  master
=> Compressing and cleaning up git repository

=> Appending nvm source string to /home/kawasaki8108/.bashrc
=> Appending bash_completion source string to /home/kawasaki8108/.bashrc
=> Close and reopen your terminal to start using nvm or run the following to use it now:

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
$ export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
$ command -v nvm #nvmと帰ってくればok
$ nvm -v
0.39.7
$ nvm install stable --latest-npm #安定しているもののうち一番新しいverでnpmインストール
Downloading and installing node v21.6.2...
Downloading https://nodejs.org/dist/v21.6.2/node-v21.6.2-linux-x64.tar.xz...
#########・・・・・####### 100.0%
Computing checksum with sha256sum
Checksums matched!
Now using node v21.6.2 (npm v10.2.4)
Creating default alias: default -> stable (-> v21.6.2)
$ nodejs -v
v12.22.9
$ node -v
v21.6.2
$ npm -v
10.2.4
$ npm version
{
  npm: '10.2.4',
  node: '21.6.2',
  acorn: '8.11.3',
  ada: '2.7.4',
  ares: '1.20.1',
  base64: '0.5.1',
  brotli: '1.1.0',
  cjs_module_lexer: '1.2.2',
  cldr: '44.0',
  icu: '74.1',
  llhttp: '9.1.3',
  modules: '120',
  napi: '9',
  nghttp2: '1.58.0',
  nghttp3: '0.7.0',
  ngtcp2: '0.8.1',
  openssl: '3.0.13+quic',
  simdjson: '3.6.3',
  simdutf: '4.0.8',
  tz: '2023c',
  undici: '5.28.3',
  unicode: '15.1',
  uv: '1.48.0',
  uvwasi: '0.0.19',
  v8: '11.8.172.17-node.19',
  zlib: '1.3.0.1-motley-40e35a7'
}
$ which npm
/home/kawasaki8108/.nvm/versions/node/v21.6.2/bin/npm
```
Zennと連携したローカルリポジトリのディレクトリに入り、改めて公式のやり方でZenn CLIを入れていきました。
```bash
$ cd zenn-public/ #Zennと連携しているリポジトリのディレクトリへ移動
$ npm init --yes #ここからやり直し
Wrote to /home/kawasaki8108/zenn-public/package.json:

{
  "name": "zenn-public",
  "version": "1.0.0",
  "description": "zenn用のリポジトリ",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/kawasaki8108/zenn-public.git"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "bugs": {
    "url": "https://github.com/kawasaki8108/zenn-public/issues"
  },
  "homepage": "https://github.com/kawasaki8108/zenn-public#readme",
  "dependencies": {
    "zenn-cli": "^0.1.153"
  },
  "devDependencies": {}
}
$ npm install zenn-cli

up to date, audited 2 packages in 412ms

found 0 vulnerabilities
$ npx zenn init
(node:37920) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
Generating .gitignore skipped.
Generating README.md skipped.

  🎉  Done!
  早速コンテンツを作成しましょう

  👇  新しい記事を作成する
  $ zenn new:article
  
  👇  新しい本を作成する
  $ zenn new:book

  👇  投稿をプレビューする
  $ zenn preview
$ zenn new:article
-bash: zenn: command not found
$ npm install zenn-cli@latest
up to date, audited 2 packages in 384ms
$ npx zenn new:article
(node:43314) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
created: articles/a0a4d33fb2a43e.md
```
記事.mdを生成することができました。が、なにかのエラーが出ています、以下の意味みたいです。<br>
>非推奨警告： `punycode`モジュールは非推奨です。代わりにユーザーランドの代替モジュールを使ってください。
（警告が作成された場所を表示するには `node --trace-deprecation ...` を使用してください。）

こちら↓の記事によると、メジャーバージョンじゃないから後で削除されるからよくない、のだと解釈しました。
>[Punycode - Node.js](https://runebook.dev/ja/docs/node/punycode)<br>
>Node.js にバンドルされている Punycode モジュールのバージョンは非推奨になります。 Node.js の将来のメジャー バージョンでは、このモジュールは削除される予定です。現在 punycode モジュールに依存しているユーザーは、代わりにユーザーランドが提供する Punycode.js モジュールの使用に切り替える必要があります。Punycode ベースの URL エンコードについては、 url.domainToASCII 、またはより一般的には WHATWG URL API を参照してください。

でもとりあえず、指示通りのコマンド叩いておきました↓。
```bash
$ node --trace-deprecation ...
node:internal/modules/cjs/loader:1152
  throw err;
  ^

Error: Cannot find module '/home/kawasaki8108/...'
    at Module._resolveFilename (node:internal/modules/cjs/loader:1149:15)
    at Module._load (node:internal/modules/cjs/loader:990:27)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:142:12)
    at node:internal/main/run_main_module:28:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v21.6.2
$ node -v
v21.6.2
```
こちらの記事からヒントを得て、LTSのバージョンを確認することにしました。
>[ERROR：[DEP0040] DeprecationWarning: The punycode module is deprecated.の解決法](https://tomatosauce.jp/punycode-deprecated/)

```bash
$ nvm ls-remote --lts
         v4.2.0   (LTS: Argon)
         v4.2.1   (LTS: Argon)
        ~~~~~~
       v18.19.0   (LTS: Hydrogen)
       v18.19.1   (Latest LTS: Hydrogen)
        v20.9.0   (LTS: Iron)
       v20.10.0   (LTS: Iron)
       v20.11.0   (LTS: Iron)
       v20.11.1   (Latest LTS: Iron)
#こちらのコマンドでもok
$ nvm ls
->      v21.6.2
         system
default -> stable (-> v21.6.2)
iojs -> N/A (default)
unstable -> N/A (default)
node -> stable (-> v21.6.2) (default)
stable -> 21.6 (-> v21.6.2) (default)
lts/* -> lts/iron (-> N/A)
lts/argon -> v4.9.1 (-> N/A)
lts/boron -> v6.17.1 (-> N/A)
lts/carbon -> v8.17.0 (-> N/A)
lts/dubnium -> v10.24.1 (-> N/A)
lts/erbium -> v12.22.12 (-> N/A)
lts/fermium -> v14.21.3 (-> N/A)
lts/gallium -> v16.20.2 (-> N/A)
lts/hydrogen -> v18.19.1 (-> N/A)
lts/iron -> v20.11.1 (-> N/A)
```
てことで、20.11.1を入れてあとで`nvm use 20.11.1`をしようと思います。
```bash
$ nvm install 20.11.1
Downloading and installing node v20.11.1...
Downloading https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-x64.tar.xz...
##########・・・・・#### 100.0%
Computing checksum with sha256sum
Checksums matched!
Now using node v20.11.1 (npm v10.2.4)
$ node -v
v20.11.1
$ npm -v
10.2.4
$ nvm use 20.11.1
Now using node v20.11.1 (npm v10.2.4) #使ってるから大丈夫みたいですね
```
もう一回、記事を新規作成してみたら、エラーなく生成されました。
```bash
$ npx zenn new:article
created: articles/391299145cdbf2.md
#消しときます↓
$ ls articles/
391299145cdbf2.md
$ rm articles/391299145cdbf2.md
$ ls articles/
$ ls
README.md  articles  books  node_modules  package-lock.json  package.json  test1  zenn-public
```
githubへpushしてブラウザで表示するところまでやってみます。
```bash
$ npx zenn preview
👀 Preview: http://localhost:8000
```

# 結果
ブラウザのアドレスバーで`http://localhost:8000`をたたくと以下の通り表示できました。<br>
![localhost:8000ブラウザ表示](/images/20240221-beginzenn/zenn031.png)<br>
また、`git push`した後は連携しているGitHub側で、ブラウザ上で編集できます。アドレスバーでgithub.comをgithub.devに変え、VScode拡張機能「Zenn Preview for github.dev」をインストール。<br>
（参考：[Zennのコンテンツをgithub.devで編集する](https://zenn.dev/zenn/articles/usage-github-dev)）<br>
![github.dev1](/images/20240221-beginzenn/zenn033.png)<br>
上図の右上の「Z」マーク押下して以下の通り表示できます。<br>
![github.dev2](/images/20240221-beginzenn/zenn032.png)<br>


# 感想
* とりあえず、ローカルでZenn記事を編集し、GitHubへpushすることでZennと連携できる環境は整いました。
* 記事編集は、まずはローカルで編集し、都度localhost:8000か拡張機能などでプレビューで確認し、`git push`後にgithub.devで最終確認・都度編集・commitすることがいいかなと思いました。そして問題なければ`published: true`にする形。
* 実は`git push`したときにも、認証方法がらみの問題でpushできずつまづいてましたので、別途でUpしようと思います。

---
# 後日追記
## 実行するnodeのバージョン
後日、新たに記事作成しようとするとまた、punycodeモジュールの件で警告されました。先日の`nvm use 20.11.1`はそのログインのタイミング
```bash
$ npx zenn new:article --slug 20240222-setprompt
(node:4578) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
created: articles/20240222-setprompt.md
$ node -v #え？と思って確認
v21.6.2
$ nvm ls #改めてdefault確認
       v20.11.1
->      v21.6.2
         system
default -> stable (-> v21.6.2)
iojs -> N/A (default)
unstable -> N/A (default)
node -> stable (-> v21.6.2) (default)
stable -> 21.6 (-> v21.6.2) (default)
～～～～
```
defaultで使用するバージョンを設定しました。
```bash
$ nvm alias default v20.11.1
default -> v20.11.1
$ exit #再起動のためいったん抜ける
logout
#Ubuntuを起動
$ nvm ls
->     v20.11.1 #defaultが変わったことを確認できました
        v21.6.2
         system
default -> v20.11.1
iojs -> N/A (default)
unstable -> N/A (default)
node -> stable (-> v21.6.2) (default)
stable -> 21.6 (-> v21.6.2) (default)
$ npx zenn new:article
created: articles/922fdd843602c6.md #大丈夫そう・・。
```
以上