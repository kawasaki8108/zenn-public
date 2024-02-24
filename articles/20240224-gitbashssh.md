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
2. 別でWSL2-UbuntuからGitHub連携のためにトークン発行したので、そのトークンをコントロールパネルの資格情報に入れ直しGitBashからもGitHub連携できるようにしました
3. 挙動確認のために資格情報に入れたPWを変えてエラー内容確認し、もとのトークンに戻したら、403エラーに遭遇しました
