---
title: "サーバー外形監視ツール UptimeKuma をEC2(Ubuntu)に導入しhttpsで接続する"
emoji: "🐻"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [UptimeKuma,EC2,Zabbix,LetsEncrypt,StatusCake]
published: false
---
# 「外形監視」の認識合わせ
外形監視という言葉自体あまりググってもメジャーそうではなかったので、以下の意味合いで使うと示します。
- サーバーの死活監視のうち、監視対象のエンドポイント（ログイン画面やヘルスチェック用のURLなど）に対してhttpリクエストしステータスコードからDown(死)/Up(活)を検知するもの
- サーバー内部のメモリ使用率やCPU使用率を取得・監視するものではない（pull型ではなく言うなればpush型）

# 背景
- 現行運用ではSaaSの**UptimeRobot**を外形監視ツールとして使用していました。
- インシデントとはならないレベルでしたが**UptimeRobot**には時折リクエスト漏れが発生していることがわかり、代替候補を探していました。
- 代替候補として他のSaaSである**StatusCake**を試しましたが、こちらもリクエスト漏れは時折ありました。
- **Zabbix,Nagios**も候補として調査しましたが、今回要求する程度と比べて機能がリッチであり、導入・運用の手間の天秤を考え、検証の優先度は下げました。
- **UptimeKuma**も**Zabbix**などと同じようにOSSですが、導入と運用が容易そうでしたので導入検証しました。
- ちなみに外形監視ツールとして求める主な要件は以下で、運用検証したところ満たしていました
    :::details 要件
    - Slack通知可能で、通知内容に任意の文字列を設定出来る（メンションできる）
    - 通知メッセージ内に監視対象URL(サイト)へのリンクが設定できる
    - 待機時間は可能なら10秒程度（10秒でタイムアウト）
    - コストは月3000円程度に抑えたい
    - チェック間隔が1分
    :::

# 目的
- EC2に**UptimeKuma**(https://github.com/louislam/uptime-kuma)を導入する
- Let's EncryptのSSL証明書をKumaサーバーに導入しhttpsでKumaの管理画面へ接続する
- 本記事のスコープ外）
  - SSL証明書を自動更新するためのcrotabやシェルスクリプトファイルの設定
  - 導入完了後のUptimeKumaの管理画面での各種設定方法
  参考記事）https://gihyo.jp/admin/serial/01/ubuntu-recipe/0707

2個目はサブ的なスコープですが、参考記事があまりなく、一番難渋したので記事にしました。。

# 前提
- VPCなどのネットワーク系リソース、EC2などは作成済み
- Route53で登録済みのホストゾーンを使い、UptimeKuma用の任意のドメインを登録し固定IPと紐付け済み
  - 例：`{uptimekuma用の任意の名称}.{ホストゾーン名}`とEC2と関連づけたElasticIPを紐付け(Aレコード)
  - 本記事ではサンプルとしてドメイン名は`hoge.example.com`としておきます。
- EC2は以下の環境
  - OS：Linux（ubuntu 24.04)
  - アーキテクチャ：arm64

# 導入
1. サーバー起動、再起動、停止、インスタンス再起動時に自動起動設定
    - nvmからnpm、nodeをインストール
        
        ```bash
        $ pwd && whoami
        /home/ubuntu
        ubuntu
        #nvmインストール　https://github.com/nvm-sh/nvm
        $ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        $ export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        $ [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        $ nvm -v
        0.40.1
        
        #npm、nodeインストール
        $ nvm install 18
        $ npm -v
        10.7.0
        $ node -v
        v18.20.4
        
        #OSS:UptimeKumaをDLしてセットアップ
        $ git clone https://github.com/louislam/uptime-kuma.git
        $ cd uptime-kuma
        $ npm run setup
        $ npm install pm2 -g && pm2 install pm2-logrotate
        $ pm2 start server/server.js --name uptime-kuma #サーバー起動
        $ pm2 save && pm2 startup #インスタンス再起動時にサーバー自動起動
        [PM2] Saving current process list...
        [PM2] Successfully saved in /home/ubuntu/.pm2/dump.pm2
        [PM2] Init System found: systemd
        [PM2] To setup the Startup Script, copy/paste the following command:
        sudo env PATH=$PATH:/home/ubuntu/.nvm/versions/node/v18.20.4/bin /home/ubuntu/.nvm/versions/node/v18.20.4/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu--hp /home/ubuntu
        ```
2. 受付ポートの変更
    - デフォルトの受付ポートが3001なので、80で受け付けるように環境変数を設定する
        
        ```bash
        $ cd ~/uptime-kuma
        $ vim .env
        #以下入力して保存(wq)
        UPTIME_KUMA_PORT=80
        $ pm2 restart uptime-kuma
        #この時点では80の（特権）ポートを使う権限がないので受け付けられずエラーとなる
        ```
        
    - 非特権ユーザーで特権ポート（80、443など）にバインドできるようにする設定
        
        ケイパビリティ（特権）の設定をするためのパッケージをインストールする
        
        ```bash
        $ which node
        -> /home/ubuntu/.nvm/versions/node/v18.20.4/bin/node #あとで使う
        $ sudo aptinstall libcap2-bin #インストール済みだった
        ```
        
        :::details 補足：`libcap`の説明
        `libcap` は Linux の「Capability（ケイパビリティ）」を操作するためのツールで、プログラムに対して特定の特権（能力）だけを付与することができます。
        これにより、特定のプログラムが root 権限なしでも特定の動作（この場合は特権ポートへのアクセス）を行えるようになります。
        :::
        
    - nodeに、特権ポートにバインドする特権を付与する
        
        ```bash
        $ sudo setcap cap_net_bind_service=+ep /home/ubuntu/.nvm/versions/node/v18.20.4/bin/node #nodeの稼働元のパスを入れる
        $ pm2 restart uptime-kuma #この時点で80ポートで受け付けられるようになる
        ```
        
        :::details 補足：`setcap cap_net_bind_service=+ep ~`の説明
        Node.js 実行ファイルに対して `cap_net_bind_service` というケイパビリティ（特権）を付与します。
        - **`setcap`** は、プログラムにケイパビリティを付与するコマンドです。
        - **`cap_net_bind_service=+ep`** は、ネットワークの特権ポート（1024未満のポート）にバインドするためのケイパビリティを、Node.js 実行ファイルに「有効」かつ「永続的」に付与するという意味です。
            - `cap_net_bind_service`：特権ポートにバインドするためのケイパビリティ。
            - `+ep`：`e` は有効 (`effective`)、`p` は永続的 (`permitted`) な権限を意味します。
        - `home/ubuntu/.nvm/versions/node/v18.20.4/bin/node` は、Node.js 実行ファイルのパスです。このファイルに対して特権を付与します。
        :::
3. Let's Encrypt導入
    - certbotをインストール
        
        ```bash
        sudo apt update
        sudo apt install certbot
        pm2 stop uptime-kuma # 80ポートでのプロセスが動いているとあとで怒られるのでここで止めておく
        ```
        
    - 証明書を取得
        
        ```bash
        sudo certbot certonly --standalone -d hoge.example.com
        
        (Enter 'c' to cancel):hoge@example.com #メールアドレスが聞かれるので、入力
        
        #ウィザードに沿って答えていく
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Please read the Terms of Service at
        https://letsencrypt.org/documents/LE-SA-v1.4-April-3-2024.pdf. You must agree in
        order to register with the ACME server. Do you agree?
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        (Y)es/(N)o: Y
        
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Would you be willing, once your first certificate is successfully issued, to
        share your email address with the Electronic Frontier Foundation, a founding
        partner of the Let's Encrypt project and the non-profit organization that
        develops Certbot? We'd like to send you email about our work encrypting the web,
        EFF news, campaigns, and ways to support digital freedom.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        (Y)es/(N)o: N
        Account registered.
        Requesting a certificate for hoge.example.com
        
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Could not bind TCP port 80 because it is already in use by another process on
        this system (such as a web server). Please stop the program in question and then
        try again.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        (R)etry/(C)ancel: R #この時は80ポートをKumaで使っていたので一旦別シェルでpm2 stop uptime-kumaで止めてから再度「R」エンターした
        
        Successfully received certificate. #証明書類が保存される
        Certificate is saved at: /etc/letsencrypt/live/hoge.example.com/fullchain.pem #証明書
        Key is saved at:         /etc/letsencrypt/live/hoge.example.com/privkey.pem #秘密鍵
        This certificate expires on 2024-12-19.
        These files will be updated when the certificate renews.
        Certbot has set up a scheduled task to automatically renew this certificate in the background.
        
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        If you like Certbot, please consider supporting our work by:
         * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
         * Donating to EFF:                    https://eff.org/donate-le
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        ```
4. `/home/ubuntu/{live,archive}`ディレクトリ以下の権限変更(所有グループに実行権限必要)
uptimekumaの実行ユーザーに証明書ファイルを読み込める権限を与えないと443接続できないため。
    - pm2の実行ユーザーを確認 →「ubuntu」とわかる
        
        ```bash
        $ pm2 start server/server.js --name uptime-kuma
        $ pm2 list
        [PM2] Starting /home/ubuntu/uptime-kuma/server/server.js in fork_mode (1 instance)
        [PM2] Done.
        ┌────┬──────────────────┬─────────────┬─────────┬─────────┬──────────┬────────┬──────┬───────────┬──────────┬──────────┬──────────┬──────────┐
        │ id │ name             │ namespace   │ version │ mode    │ pid      │ uptime │ ↺    │ status    │ cpu      │ mem      │ user     │ watching │
        ├────┼──────────────────┼─────────────┼─────────┼─────────┼──────────┼────────┼──────┼───────────┼──────────┼──────────┼──────────┼──────────┤
        │ 1  │ uptime-kuma      │ default     │ 1.23.13 │ fork    │ 1642     │ 0s     │ 0    │ online    │ 0%       │ 44.3mb   │ ubuntu   │ disabled │
        └────┴──────────────────┴─────────────┴─────────┴─────────┴──────────┴────────┴──────┴───────────┴──────────┴──────────┴──────────┴──────────┘
        $ ps auxf | grep pm2
        ubuntu      1664  0.0  0.1   6672  1792 pts/1    S+   06:53   0:00                                  \_ grep --color=auto pm2
        ubuntu      1609  1.2  6.3 902268 59656 ?        Ssl  06:52   0:01 PM2 v5.4.2: God Daemon (/home/ubuntu/.pm2)
        ubuntu      1620  0.7  6.1 903184 57664 ?        Ssl  06:52   0:00  \_ node /home/ubuntu/.pm2/modules/pm2-logrotate/node_modules/pm2-logrotate/app.js
        ```
        
    - ubuntuの所属グループを確認してユーザー「ubuntu」は「ubuntu」グループに入っているとわかる
        
        ```bash
        $ cat /etc/passwd | grep ubuntu
        ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash #左から・ユーザー名・パスワード（xで表示される）・ユーザーID（UID）・グループID・何も表示されない箇所は作成時に任意でつけるコメント・ユーザーのホームディレクトリ・シェルの場所
        $ cat /etc/group | grep ubuntu
        adm:x:4:syslog,ubuntu #左からグループ名、グループのパスワード、グループID、サブグループ
        cdrom:x:24:ubuntu
        sudo:x:27:ubuntu
        dip:x:30:ubuntu
        lxd:x:104:ubuntu
        ubuntu:x:1000:
        ```
        
    - 権限変更前（デフォルト）
        
        :::details `/etc/letsencrypt/{live,archive}`以下はubuntuにはアクセス権限がないとわかる
        
        ```bash
        $ sudo ls -ald /etc/letsencrypt/
        drwxr-xr-x 7 root root 4096 Sep 24 06:01 /etc/letsencrypt/ #ここまではその他ユーザーでも入れる(xがある)ので何もしなくてもok
        $ sudo ls -ald /etc/letsencrypt/{live,archive}
        drwx------ 3 root root 4096 Sep 24 06:01 /etc/letsencrypt/archive
        drwx------ 3 root root 4096 Sep 24 06:01 /etc/letsencrypt/live
        $ sudo ls -al /etc/letsencrypt/{live,archive}/hoge.example.com
        /etc/letsencrypt/archive/hoge.example.com:
        total 24
        drwxr-xr-x 2 root root 4096 Sep 24 06:01 . #hoge.example.comディレクトリは所有グループだけ変えればok
        drwx------ 3 root root 4096 Sep 24 06:01 ..
        -rw-r--r-- 1 root root 1306 Sep 24 06:01 cert1.pem
        -rw-r--r-- 1 root root 1566 Sep 24 06:01 chain1.pem
        -rw-r--r-- 1 root root 2872 Sep 24 06:01 fullchain1.pem
        -rw------- 1 root root  241 Sep 24 06:01 privkey1.pem #ubuntuに読み取り権限がいる
        
        /etc/letsencrypt/live/hoge.example.com:
        total 12
        drwxr-xr-x 2 root root 4096 Sep 24 06:01 . #hoge.example.comディレクトリは所有グループだけ変えればok
        drwx------ 3 root root 4096 Sep 24 06:01 ..
        -rw-r--r-- 1 root root  692 Sep 24 06:01 README
        lrwxrwxrwx 1 root root   51 Sep 24 06:01 cert.pem -> ../../archive/hoge.example.com/cert1.pem
        lrwxrwxrwx 1 root root   52 Sep 24 06:01 chain.pem -> ../../archive/hoge.example.com/chain1.pem
        lrwxrwxrwx 1 root root   56 Sep 24 06:01 fullchain.pem -> ../../archive/hoge.example.com/fullchain1.pem
        lrwxrwxrwx 1 root root   54 Sep 24 06:01 privkey.pem -> ../../archive/hoge.example.com/privkey1.pem
        ```
        :::
        
    - 権限変更操作
        - `/etc/letsencrypt/{live,archive}`以下の所有グループを再帰的にubuntuにし、
        - `{live,archive}`にubuntuグループのメンバーが証明書ディレクトリにアクセスできるようにする
        - `/etc/letsencrypt/live`のリンク先`/etc/letsencrypt/archive/hoge.example.com/privkey1.pem`を読み込めるようにする（`640`）
        
        ```bash
        $ sudo chown -R :ubuntu /etc/letsencrypt/{live,archive}
        $ sudo chmod 750 /etc/letsencrypt/{live,archive}
        $ sudo chmod 640 /etc/letsencrypt/archive/hoge.example.com.com/privkey*
        #確認
        $ sudo ls -al /etc/letsencrypt/{live,archive}/hoge.example.com.com
        /etc/letsencrypt/archive/hoge.example.com.com:
        total 24
        drwxr-xr-x 2 root ubuntu 4096 Sep 24 06:01 .
        drwxr-x--- 3 root ubuntu 4096 Sep 24 06:01 ..
        -rw-r--r-- 1 root ubuntu 1306 Sep 24 06:01 cert1.pem
        -rw-r--r-- 1 root ubuntu 1566 Sep 24 06:01 chain1.pem
        -rw-r--r-- 1 root ubuntu 2872 Sep 24 06:01 fullchain1.pem
        -rw-r----- 1 root ubuntu  241 Sep 24 06:01 privkey1.pem
        
        /etc/letsencrypt/live/hoge.example.com.com:
        total 12
        drwxr-xr-x 2 root ubuntu 4096 Sep 24 06:01 .
        drwxr-x--- 3 root ubuntu 4096 Sep 24 06:01 ..
        -rw-r--r-- 1 root ubuntu  692 Sep 24 06:01 README
        lrwxrwxrwx 1 root ubuntu   51 Sep 24 06:01 cert.pem -> ../../archive/hoge.example.com/cert1.pem
        lrwxrwxrwx 1 root ubuntu   52 Sep 24 06:01 chain.pem -> ../../archive/hoge.example.com/chain1.pem
        lrwxrwxrwx 1 root ubuntu   56 Sep 24 06:01 fullchain.pem -> ../../archive/hoge.example.com/fullchain1.pem
        lrwxrwxrwx 1 root ubuntu   54 Sep 24 06:01 privkey.pem -> ../../archive/hoge.example.com/privkey1.pem
        ```
5. https接続のため、アプリケーションルートの`.env`ファイルに以下追記後、リスタート（`pm2 restart uptime-kuma`）する
    
    ```bash
    UPTIME_KUMA_PORT=443
    UPTIME_KUMA_SSL_KEY=/etc/letsencrypt/live/hoge.example.com/privkey.pem
    UPTIME_KUMA_SSL_CERT=/etc/letsencrypt/live/hoge.example.com/fullchain.pem
    ```
    
    :::details 成功時のログ(443でリッスンできていることがわかる)
    ```bash
    /home/ubuntu/.pm2/logs/uptime-kuma-out.log last 15 lines:
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: SQLite config:
    1|uptime-k | [ { journal_mode: 'wal' } ]
    1|uptime-k | [ { cache_size: -12000 } ]
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: SQLite Version: 3.41.1
    1|uptime-k | 2024-09-24T07:53:01Z [SERVER] INFO: Connected
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: Your database version: 10
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: Latest database version: 10
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: Database patch not needed
    1|uptime-k | 2024-09-24T07:53:01Z [DB] INFO: Database Patch 2.0 Process
    1|uptime-k | 2024-09-24T07:53:01Z [SERVER] INFO: Load JWT secret from database.
    1|uptime-k | 2024-09-24T16:53:01+09:00 [MAINTENANCE] INFO: Generate cron for maintenance id: 1
    1|uptime-k | 2024-09-24T16:53:01+09:00 [SERVER] INFO: Adding route
    1|uptime-k | 2024-09-24T16:53:01+09:00 [SERVER] INFO: Adding socket handler
    1|uptime-k | 2024-09-24T16:53:01+09:00 [SERVER] INFO: Init the server
    1|uptime-k | 2024-09-24T16:53:01+09:00 [SERVER] INFO: Listening on 443
    ```
    :::
6. `https://hoge.example.com`をブラウザからリクエストして管理画面が表示できれば完了

# 感想
- UptimeKuma自体を稼働させるまでは非常に簡単なのでおすすめです。
- [UptimeKumaのwiki](https://github.com/louislam/uptime-kuma/wiki/Environment-Variables)に環境変数の設定方法は紹介されているのですが、README通りのサーバースタートの方法だと権限の問題で証明書ファイルを読み込めずエラー（`Error: EACCES: permission denied`）となりました。
- ポイントは**導入_2**の非特権ユーザーでも特権ポートを使えるようにする設定と、**導入_4**の環境変数に入れた証明書関連ファイルのパスに対してubuntuユーザーが読み込めるようにすることでした。
- 証明書ファイルの`/etc/letsencrypt/live/hoge.example.com/privkey.pem`などはシンボリックリンクになっています。これ自体は権限`777`なのですが、リンク先のパスに対する読み込み権限とその親ディレクトリに対しての実行権限がデフォルトではないのです。読み込みたいファイルパスへの権限変更はわかるのですが、親ディレクトリに実行権限がないと配下のディレクトリやファイルへたどり着けないとは知らずハマりました。
- 私のハマりポイントはLinuxでの権限の仕組みやアプリケーションを443でリッスンさせて動かすというところでしたが、この機に勉強できてよかったです。

# 参考記事🙇🏻
- 非特権ユーザーが特権ポートを使えるようにする
[Give Safe User Permission To Use Port 80](https://www.digitalocean.com/community/tutorials/how-to-use-pm2-to-setup-a-node-js-production-environment-on-an-ubuntu-vps#give-safe-user-permission-to-use-port-80)
- 証明書関連ファイルの読み込みができない件
https://stackoverflow.com/questions/48078083/lets-encrypt-ssl-couldnt-start-by-error-eacces-permission-denied-open-et
- Let's Encryptの設定方法
https://qiita.com/RubiLeah/items/c2252a6c42f60fc3677b
- root以外のユーザからのSSL証明書等へのアクセスの確保
https://warexperimental.hatenablog.com/entry/2020/05/19/075535
