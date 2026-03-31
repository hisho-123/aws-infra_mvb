# AWS Infra for MVB

## 概要
現在、さくらのVPSで公開しているmy-vocaburary-bookを、AWS上で公開するように変更する。
また、構成を簡単な冗長化構成にしたい。

## 構成

### 構成図
chromeにて下記構成図をビルドするには、'Markdown Diagrams'という拡張をインストールしてください。
[mermaid版はこちら](./mermaid/diagrams.md)
```plantuml
@startuml
!include <awslib/AWSCommon>
!include <awslib/Compute/EC2>
!include <awslib/Database/RDS>
!include <awslib/NetworkingContentDelivery/ElasticLoadBalancingApplicationLoadBalancer>
!include <awslib/NetworkingContentDelivery/CloudFront>
!include <awslib/NetworkingContentDelivery/Route53>
!include <awslib/Storage/SimpleStorageService>
!include <awslib/DeveloperTools/CodeDeploy>
!include <awslib/SecurityIdentityCompliance/CertificateManager>
!include <awslib/Groups/AWSCloud>
!include <awslib/Groups/VPC>
!include <awslib/Groups/AvailabilityZone>
!include <awslib/Groups/Region>

actor User

AWSCloudGroup(cloud) {

  Route53(r53, "Route53\nhisho-123.com", "")

  RegionGroup(global, "us-east-1") {
    CertificateManager(acm, "ACM\nCloudFront用証明書", "")
    CloudFront(cf, "CloudFront\nmy-vocabulary-book.hisho-123.com", "")
    SimpleStorageService(s3_fe, "S3\nfrontend", "")
  }

  RegionGroup(ap, "ap-northeast-1") {
    SimpleStorageService(s3_cd, "S3\nCodeDeploy\nartifacts", "")
    CodeDeploy(codedeploy, "CodeDeploy", "")

    VPCGroup(vpc) {
      ElasticLoadBalancingApplicationLoadBalancer(alb, "ALB", "")

      AvailabilityZoneGroup(az1, "AZ1") {
        EC2(web1, "EC2\nweb", "")
        RDS(db_master, "RDS\nmaster", "")
      }

      AvailabilityZoneGroup(az2, "AZ2") {
        EC2(web2, "EC2\nweb", "")
        RDS(db_replica, "RDS\nreplica", "")
      }
    }
  }
}

actor GHA_FE as "GitHub Actions\n(frontend)"
actor GHA_BE as "GitHub Actions\n(backend)"

' ユーザーアクセス
User --> r53 : DNS名前解決
r53 --> cf : HTTPS

' ACM DNS検証
r53 ..> acm : DNS検証 (CNAME)
acm ..> cf : TLS証明書

' フロントエンド配信
cf --> s3_fe : OAC

' バックエンドAPI
cf --> alb : HTTP /api/*

' バックエンド
alb --> web1
alb --> web2
web1 --> db_master
web2 --> db_master
db_master --> db_replica : replication

' CI/CD (frontend)
GHA_FE --> s3_fe : s3 sync
GHA_FE --> cf : invalidation

' CI/CD (backend)
GHA_BE --> s3_cd : upload artifact
GHA_BE --> codedeploy : create-deployment
codedeploy --> web1 : deploy
codedeploy --> web2 : deploy

web1 -[hidden] web2
@enduml
```

### アクセスフロー

#### 静的コンテンツ（HTML/CSS/JS）の取得フロー

```plantuml
@startuml
actor User

participant "Route53\n(hisho-123.com)" as R53
participant "CloudFront\n(Edge Location)" as CF
participant "CloudFront Function\n(redirect_root)" as CFF
participant "S3\n(Frontend Bucket)" as S3

User -> R53 : DNS名前解決\nmy-vocabulary-book.hisho-123.com
R53 --> User : ALIAS → CloudFront Domain

User -> CF : HTTPS GET /
CF -> CFF : Viewer Request (path="/")
CFF --> CF : 302 Redirect → /login
CF --> User : 302 /login

User -> CF : HTTPS GET /login
note over CF : キャッシュ確認\nTTL: 3600〜86400s
CF -> S3 : GET /login (OAC + SigV4署名)
S3 --> CF : HTML
CF --> User : HTTPS Response (HTML/CSS/JS)
@enduml
```

#### APIリクエストのフロー（/api/*）

```plantuml
@startuml
actor User

participant "CloudFront\n(Edge Location)" as CF
participant "ALB\n(Public Subnet)" as ALB
participant "EC2\n(Private Subnet / ASG)" as EC2
participant "RDS Master\n(Private Subnet)" as RDS

User -> CF : HTTPS POST /api/...
note over CF : キャッシュなし (TTL=0)\n全Headerを転送
CF -> ALB : HTTP POST /api/... (port 80)\n※CloudFront IPのみ許可
ALB -> EC2 : HTTP POST /api/... (port 80)\n※ALB SGからのみ許可
EC2 -> RDS : MySQL Query (port 3306)\n※Web SGからのみ許可
RDS --> EC2 : Query Result
EC2 --> ALB : HTTP Response
ALB --> CF : HTTP Response
CF --> User : HTTPS Response
@enduml
```

### 使用サービス
- Route53 (DNSホスティング、ACM DNS検証)
- CloudFront (フロントエンド配信、us-east-1 ACM)
- ACM (CloudFront用TLS証明書、us-east-1)
- S3 (フロントエンド静的ファイル / CodeDeploy アーティファクト)
- CodeDeploy (バックエンド自動デプロイ)
- Application Load Balancer
- Auto Scaling Group
- EC2
- RDS (MySQL, master/replica)


## 構築手順

1. terraformをインストール

  ```bash
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
  brew update
  brew upgrade hashicorp/tap/terraform
  ```

  バージョン確認
  ```bash
  terraform version
  ```
  ```bash
  # 出力例
  Terraform v1.14.3
  on darwin_arm64
  + provider registry.terraform.io/hashicorp/aws v4.67.0
  ```

2. aws cliをインストール

  ```bash
  brew install awscli
  ```
  確認
  ```bash
  aws --version
  ```
  ```bash
  # 出力例
  aws-cli/2.32.16 Python/3.13.11 Darwin/23.6.0 source/arm64
  ```

3. aws configure

  下記コマンド以降、awsコマンドを実行する際に、awsアカウントの認証情報を入力する。
  ```bash
  aws configure
  ```
  ```bash
  # 出力例
  AWS Access Key ID [None]:
  AWS Secret Access Key [None]:
  Default region name [None]: ap-northeast-1
  Default output format [None]: json
  ```

## 環境変数設定

Terraformで使用する機密情報は `.env` ファイルで管理します。

1. `.env` ファイルにデータベースパスワードを設定

   ```bash
   export TF_VAR_db_password="your_secure_password_here"
   ```

2. 環境変数が読み込まれたか確認

   ```bash
   echo $TF_VAR_db_password
   ```

## Terraform実行

1. 初期化

   ```bash
   terraform init
   ```

2. **環境変数を読み込み（重要）**

   ```bash
   source .env
   ```

3. プラン確認

   ```bash
   terraform plan
   ```

## CI/CDセットアップ

Terraform適用後、CI/CDが動作するために以下を手動で1回実施する。

### 1. terraform outputで値を確認

```bash
source .env
terraform output
```

### 2. SSM Parameter Store にバックエンド環境変数を登録（初回のみ）

バックエンドのEC2が起動時に読み込む環境変数をSSMに保存する。

```bash
# JWT_KEY を生成
openssl rand -base64 32

# SSMに登録（<>の値を置き換える）
aws ssm put-parameter \
  --name "/mvb/backend/env" \
  --type SecureString \
  --value "DB_USER=admin
DB_PASSWORD=<.envのTF_VAR_db_passwordの値>
DB_HOST=<terraform output db_master_endpoint の値（末尾の:3306を除いたホスト名部分）>
DB_PORT=3306
DB_NAME=my_vocabulary_book
JWT_KEY=<openssl rand -base64 32 で生成した値>" \
  --region ap-northeast-1
```

### 3. GitHub Repository Secrets を設定

各リポジトリの `Settings > Secrets and variables > Actions > Repository secrets` に追加する。

**`my-vocabulary-book_backend` リポジトリ**

| Secret名 | 値の取得コマンド |
|---|---|
| `AWS_ROLE_ARN_BACKEND` | `terraform output github_actions_backend_role_arn` |
| `CODEDEPLOY_BUCKET` | `terraform output codedeploy_artifacts_bucket` |
| `CODEDEPLOY_APP` | `terraform output codedeploy_app_name` |
| `CODEDEPLOY_DEPLOYMENT_GROUP` | `terraform output codedeploy_deployment_group_name` |

**`my-vocabulary-book_frontend` リポジトリ**

| Secret名 | 値の取得コマンド |
|---|---|
| `AWS_ROLE_ARN_FRONTEND` | `terraform output github_actions_frontend_role_arn` |
| `FRONTEND_BUCKET` | `terraform output frontend_s3_bucket` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `terraform output cloudfront_distribution_id` |

## Session Managerでの接続方法

EC2インスタンスへの接続は、Session Managerを使用します。

```bash
# インスタンスID取得
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=my-vocaburary-book-web" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output table

# Session Manager接続
aws ssm start-session --target <instance-id>
```

## HTTPS対応（ACM証明書取得後）

HTTPS化する場合は、ACM証明書を取得後、`terraform.tfvars` に以下を追加してください。

```terraform
certificate_arn = "arn:aws:acm:ap-northeast-1:xxxx:certificate/xxxx"
```
