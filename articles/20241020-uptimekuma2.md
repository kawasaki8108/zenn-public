---
title: "サーバー外形監視ツール UptimeKuma -運用編：監視設定とKuma自体の監視-"
emoji: "🧸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [UptimeKuma,Route53,Lambda,CloudWatch,EC2]
published: false
---
導入編はこちら：
https://zenn.dev/kawasaki8108/articles/20241019-uptimekuma1

# 前提
- EC2で[**UptimeKuma**](https://github.com/louislam/uptime-kuma)を導入し稼働確認済み
  詳細は[導入編](https://zenn.dev/kawasaki8108/articles/20241019-uptimekuma1)を参照ください

# 背景
- UptimeKumaの管理画面で何が設定できるのかあまり参考記事がなかったので記事にしようと思いました。

# 目的
- Kumaでの監視設定内容とKuma自体を監視する体制を紹介する
を始める
  - 監視対象の設定と設定内容の紹介
  - Slackへの通知設定
  - メンテナンス機能を使う
- Kuma自体が問題なくチェックできているかを監視する仕組みを作る
  - Route53のヘルスチェックをKumaサーバー(EC2)に対して行う
  - Kumaサーバーがリクエストを意図した間隔で送れているかをLambdaのCloudWatchメトリクス`Invocations`の記録とアラートで検知する

# 