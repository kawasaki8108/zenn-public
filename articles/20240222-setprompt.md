---
title: "Ubuntuのプロンプトでgitのブランチ名を表示"
emoji: "🌿"
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
$ echo $SHELL #使用しているシェルを確認
/bin/bash
$ echo $PS1 #PS1の設定内容を確認
\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
```
PS1のデフォルトの設定内容についての参考記事）
* [Bashのプロンプトをカスタマイズする【色変・時間表示】](https://zenn.dev/kcabo/articles/555d9cc6dad0c3)
* [[ask Ubuntu]What does "${debian_chroot:+($debian_chroot)}" do in my terminal prompt?](https://askubuntu.com/questions/372849/what-does-debian-chrootdebian-chroot-do-in-my-terminal-prompt)
* [Bash Reference Manual](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html)
* [プロンプトの色を変える](https://qiita.com/arakaki_tokyo/items/e54d95911ec7a22a7846)

# プロンプトの設定箇所と仕組理解
* Udemyでbashの勉強少ししていたので、上記のPS1の設定を「bash_profile」か「bashrc」かに記述追加するイメージがあります。
* 教えてもらったこととググったことをまとめました。下表のとおり読み込まれるようです。

|設定ファイル|読み込みタイミング|用途・影響範囲|
|--|--|--|
|/etc/profile|ユーザーログイン時に読み込まれるファイル|全ユーザ共通の設定を書き込む|
|~/.bash_profile|ユーザーログイン時に読み込まれるファイル<br> |ユーザー毎に記載する|
|~/.profile|~/.bash_profileがないなら読み込まれる|ユーザー毎に記載する|
|~/.bashrc|bashを対話的に起動するとき（≠シェルスクリプト実行）に読み込まれる|ユーザー毎に記載する|


参考記事）
* [【bash】初期ファイルの読み込む順番についてのお話](https://fujiball.co.jp/recruitment/blog/59/)
* [Bash: .bashrcと.bash_profileの違いを今度こそ理解する](https://techracho.bpsinc.jp/hachi8833/2021_07_08/66396)
* [「.bashrc」と「.bash_profile」の使いこなし](https://envader.plus/article/249)


一旦ユーザーのホームディレクトリで上表のファイルがあるかを確認しました。
```bash
$ cd
$ pwd
/home/kawasaki8108
$ la | grep .bash
.bash_history
.bash_logout
.bashrc #.bash_profileはデフォルトではないようです。
$ cat .bashrc #ほしいところだけ抜粋します↓
# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    #↑↑↑↑↑↑ここをいじるんだと思います！↑↑↑↑
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```
* OSによっては「.bash_profile」がデフォルトでないことはあるそうなので、新規作成してPATHを通すのもありです。
* 「.bash_profile」はなく、「.profile」がありました。中身みるとログイン時にも.bashrcを呼び出しているみたいです。
```bash:~/.profile
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi
```
* 今回の目的的にはいらなそうなので、実際に.bashrcをいじってみて挙動確認してみます。

▼`if [ "$color_prompt" = yes ]; then`の`PS1=`のところ
```diff bash:.bashrcの変更前後
- PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
+ PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\]\u@\h\[\033[00m\]:\[\033[42m\]\w\[\033[00m\]\$ '
```
▼変更前<br>
![変更前](/images/20240222-setprompt/prompt010.png)<br>
▼変更後<br>
![変更後](/images/20240222-setprompt/prompt011.png)<br>

## 小まとめ
* `~/.bashrc`の`color_prompt`のifブロック内のPS1の設定を修正する
* gitのブランチ名の設定をこの記述の末尾にいれるイメージ


# gitのブランチ名をいれる
こちらの記事を参考に実施していきます。[gitの公式](https://github.com/git/git/blob/v2.31.1/contrib/completion)で、ブランチ名表示するための設定ファイルを提供してくれているそうなので、入れていきます。
* [Git ことはじめ (for Ubuntu)](https://zenn.dev/kusaremkn/articles/1262af3dea93a3)
* [bash + git環境でプロンプトにブランチ名と作業ツリーの状態を表示させて快適な開発環境を作る](https://qiita.com/ryoichiro009/items/7957df2b48a9ea6803e0)<br>
* curlのオプションの参考記事）https://xtech.nikkei.com/it/atcl/column/14/230520/080400003/


```bash
$ pwd
/home/kawasaki8108
$ echo $HOME
/home/kawasaki8108
$ la | grep git-prompt  #現時点でホームディレクトリになし
$ la | grep git-comp    #現時点でホームディレクトリになし
$ curl https://github.com/git/git/blob/v2.31.1/contrib/completion/git-prompt.sh -o $HOME/.git-prompt.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  129k  100  129k    0     0   127k      0  0:00:01  0:00:01 --:--:--  127k
$ curl https://github.com/git/git/blob/v2.31.1/contrib/completion/git-completion.bash -o $HOME/.git-completion.bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  499k  100  499k    0     0   682k      0 --:--:-- --:--:-- --:--:--  682k
$ la | grep git-prompt
.git-prompt.sh
$ la | grep git-comp
.git-completion.bash
```
目的の設定ファイルをDLできたので、公式のコメントアウトのメッセージにも書いている↓通り、.bashrcに記述を追加していきます。
```bash:.bashrc
# for prompt
source ~/.git-completion.bash
source ~/.git-prompt.sh

GIT_PS1_SHOWDIRTYSTATE=true     #addされていないまたはcommitされていない変更の存在をそれぞれ「*」、「+」で示す
GIT_PS1_SHOWUNTRACKEDFILES=true #addされていない新規ファイルの存在を「%」で示す
GIT_PS1_SHOWSTASHSTATE=true     #stashがある場合は「$」で示す
GIT_PS1_SHOWUPSTREAM=auto       #upstreamと同期している場合は「=」、upstreamより進んでいる場合は「>」、upstreamより遅れている場合は「<」で示す

if [ "$color_prompt" = yes ]; then
    PS1='\[\033[01;36m\]\D{%Y%m%d}_\t \u@\h\[\033[00m\]:\[\033[0;32m\]\w \[\033[00m\]\[\033[1;35m$(__git_ps1 " (%s)")\033[00m\]\n\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
```
上記の設定で、一旦`exit`後、再度Ubuntuを起動するとプロンプト自体は下のキャプチャの通り想定通りできました。
![ブランチ名表示](/images/20240222-setprompt/prompt012.png)<br>

が、`source ~/.git-completion.bash`と`source ~/.git-prompt.sh`の中身がプロンプト表示の前段にターミナル表示されました。
▼その時のキャプチャ（抜粋）<br>
![エラー1](/images/20240222-setprompt/prompt022.png)
![エラー2](/images/20240222-setprompt/prompt021.png)

結局`source ~/.git-completion.bash`と`source ~/.git-prompt.sh`の記述は削除しても問題なく想定通りのプロンプト表示、また、補完もしてくれました。<br>
おそらく、`source ~/.git-completion.bash`と`source ~/.git-prompt.sh`がすでに稼働していた？似た設定ファイルがないか基本に立ち返り探しました。
参考記事）[WSL に標準でインストールされている git においてブランチ名を表示する方法]

まず、最初に読み込まれるところから↓。
```bash:/etc/profile
if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then
    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc
    fi
  else
    if [ "$(id -u)" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
  fi
fi

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
```
最初のブロック
* 環境変数PS1が設定されている場合にのみ実行
* $BASHが/bin/shでなく、/etc/bash.bashrcが存在する場合はそのファイルが読み込まれる
* ログインユーザーの権限によって#か$か決める

次のブロック
* /etc/profile.dディレクトリ内のすべての.shファイルが順番に読み込まれ、それぞれが実行される

/etc/bash.bashrc内に、`git-completion.bash`と`source ~/.git-prompt.sh`に関連する記載がないので、次に読み込まれるユーザーホームディレクトリの「.bashrc」内を改めて確認します。
```bash:~/.bashrc
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
```
```bash
$ shopt -o | grep posix
posix           off
```
posix がoffなので、条件満たすから`/etc/`か`/usr/`内の`bash_completion`を読み込むということがわかりました。`/usr/share/bash-completion/bash_completion`の中身で`/etc/bash_completion.d`の中のファイルを実行する旨がありました。
```bash:/usr/share/bash-completion/bash_completion
# source compat completion directory definitions
compat_dir=${BASH_COMPLETION_COMPAT_DIR:-/etc/bash_completion.d}
if [[ -d $compat_dir && -r $compat_dir && -x $compat_dir ]]; then
    for i in "$compat_dir"/*; do
        [[ ${i##*/} != @($_backup_glob|Makefile*|$_blacklist_glob) && -f \
        $i && -r $i ]] && . "$i"
    done
fi
```
その中身が以下の通りです。
```bash
$ la /etc/bash_completion.d
apport_completion  git-prompt
```
```bash:/etc/bash_completion.d/git-prompt
if [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
        . /usr/lib/git-core/git-sh-prompt
fi
```
そして、`/usr/lib/git-core/git-sh-prompt`の中身が`.git-prompt.sh`の中身とたぶん一緒でした。
あとからググると、同じようにやってる方がいました↓。（だいぶスマートです）
[git のブランチ名を bash のコマンドプロンプトに表示する](https://qiita.com/m-tmatma/items/d9ceba9118d5f6c1be83)

もう一つ、`.git-completion.bash`は`/usr/share/bash-completion/completions/git`のことでした。。gitを使っている時点で補完機能onになっているということだと思います。
参考記事）[Gitのタブ補完を設定する](https://qiita.com/pyon_kiti_jp/items/50d4676d50ba8db204aa)

# まとめ
* 中段の`curl`による設定ファイルＤＬは不要でした。。
* Ubuntu導入したらデフォルトでgitとgit関連のスクリプトと、呼び出すためのbashスクリプト類は入っている→プロンプト変えたければ、ユーザーホームディレクトリの`.bashrc`内のPS1の記述をカスタムすればok

# 感想
* 探し物が以前より上達した気がします。ググってあたりを付ける方法と、findコマンドなどで見つける方法とで。
* ルートディレクトリからfindするとWindows内のフォルダにも探索かかるので、除外のオプションいれるか、WSLのルートから1つ下がったところから探すのがまし。自分は前者がうまくいかなかったので後者でした。
* シェル（bash）の読み込まれる順序の理解が深まりました。