---
title: "Ubuntuのプロンプトでgitのブランチ名を表示"
emoji: ""
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [Ubuntu,プロンプト,PS1,git,branch]
published: false
---
# 背景
* Windows 11上でWSL2-Ubuntu環境
* Ubuntu導入した後ではデフォルトでブランチ名がプロンプトに表示されない
* いちいち`git branch`で確認するのが面倒なので、よくある形`(main) $`に変更したい
* 現状はこんな感じです
```bash
kawasaki8108@DESKTOP-FV4SS4B:~/zenn-public$
kawasaki8108@DESKTOP-FV4SS4B:~/zenn-public$ git branch
* main
```
* 表示形式の設定確認すると下の通り（え？なんでこんなに長い？）
```bash
$ echo $PS1
\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
```
# 仕組理解
* Udemyでbashの勉強少ししていたので、上記のPS1の設定を「bash_profile」か「bashrc」かに記述追加するイメージがあります。
* 教えてもらったことをまとめると下表のとおり読み込まれるようです。
|設定ファイル|読み込みタイミング|用途・影響範囲|
|----|----|----|
|/etc/profile|ユーザーログイン時に読み込まれるファイル|全ユーザ共通の設定を書き込む|
|~/.bash_profile|ユーザーログイン時に読み込まれるファイル|ユーザー毎に記載する|
|~/.bashrc|bashを対話的に起動するとき（≠シェルスクリプト実行）に読み込まれる|ユーザー毎に記載する|
参考）[Bash: .bashrcと.bash_profileの違いを今度こそ理解する](https://techracho.bpsinc.jp/hachi8833/2021_07_08/66396)

# 実施したこと
プロンプトの表示形式の設定を確認

