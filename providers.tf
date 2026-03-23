provider "aws" {
  region = "ap-northeast-1"
}

# CloudFront 用 ACM 証明書は us-east-1 必須
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
