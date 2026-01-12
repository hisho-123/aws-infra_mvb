# EventBridge Scheduler IAM Role
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-scheduler-role"
  }
}

resource "aws_iam_policy" "scheduler" {
  name = "${var.project_name}-scheduler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["autoscaling:UpdateAutoScalingGroup"]
        Resource = aws_autoscaling_group.main.arn
      },
      {
        Effect = "Allow"
        Action = ["rds:StartDBInstance", "rds:StopDBInstance"]
        Resource = [
          aws_db_instance.master.arn,
          aws_db_instance.replica.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}
