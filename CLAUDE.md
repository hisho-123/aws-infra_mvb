# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このリポジトリは、my-vocaburary-book（単語帳アプリケーション）をAWS上で動作させるためのTerraform IaCコードです。マルチAZ構成で冗長化されたインフラを構築します。

## 主要なコマンド

### Terraformの基本操作

```bash
# 初期化（最初の1回のみ）
terraform init

# 環境変数の読み込み（実行前に必須）
source .env

# 実行計画の確認
terraform plan

# インフラの適用
terraform apply

# インフラの削除
terraform destroy

# フォーマット
terraform fmt

# 構文チェック
terraform validate
```

### EC2への接続（Session Manager経由）

```bash
# インスタンスIDを取得
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mvb-web" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output table

# Session Managerで接続
aws ssm start-session --target <instance-id>
```

## アーキテクチャ構成

### ネットワーク階層（3層構成）

- **Public Subnet**: ALBを配置。インターネットからのトラフィックを受け付ける
- **Private Subnet**: EC2インスタンス（Auto Scaling Group）とRDSを配置。NAT Gateway経由でインターネットアクセス可能
- **マルチAZ**: 2つのAvailability Zone（ap-northeast-1a, ap-northeast-1c）に分散配置

## 変数とカスタマイズ

### 必須の環境変数

`.env`ファイルで以下を設定:
```bash
export TF_VAR_db_password="your_secure_password"
```

### terraform.tfvarsでのカスタマイズ

- `project_name`: リソース名のプレフィックス（デフォルト: "mvb"）
- `instance_type`: EC2インスタンスタイプ（デフォルト: "t2.micro"）
- `db_instance_type`: RDSインスタンスタイプ（デフォルト: "db.t3.micro"）
- `enable_schedule`: スケジュール起動/停止の有効化（デフォルト: true）
- `schedule_start`/`schedule_stop`: 起動/停止時刻のcron式
- `certificate_arn`: HTTPS用のACM証明書ARN（オプション）

## 重要な設計上の注意点

### セキュリティ

- EC2インスタンスはPrivate Subnetに配置され、直接インターネットからアクセス不可
- Session Manager経由でのみEC2にアクセス可能（SSH鍵不要）
- RDSはWebサーバーからのみアクセス可能
- 機密情報（DBパスワード、証明書ARN）は環境変数で管理

### コスト最適化

- `enable_schedule`変数でスケジュール機能を有効化すると、非営業時間にリソースを自動停止
- スケジュール起動/停止の順序:
  - 起動時: RDS Master → RDS Replica → ASG
  - 停止時: ASG → RDS Replica → RDS Master

### HTTPS対応

- ACM証明書を事前に取得し、`certificate_arn`変数に設定することでHTTPSリスナーが自動作成される
- 証明書がない場合はHTTPのみで動作

## ファイル構成

- `main.tf`: VPC、EC2、RDS、ALBなどのメインリソース定義
- `variables.tf`: 入力変数の定義
- `providers.tf`: AWSプロバイダー設定（リージョン: ap-northeast-1）
- `versions.tf`: Terraformとプロバイダーのバージョン指定
- `iam.tf`: IAMロール/ポリシー定義
- `scheduler.tf`: EventBridge Schedulerによる自動起動/停止設定
- `outputs.tf`: VPC ID、ALB DNS名、RDSエンドポイントなどの出力値
- `.gitignore`: `.env`、`*.tfstate`、`*.tfvars`などを除外
