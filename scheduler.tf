# ========================================
# ASG Scheduler
# ========================================

# 営業時間開始時にASGを起動（スケールアウト）
resource "aws_scheduler_schedule" "asg_start" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-asg-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_start
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:autoscaling:updateAutoScalingGroup"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      AutoScalingGroupName = aws_autoscaling_group.main.name
      MinSize              = var.asg_desired_capacity
      MaxSize              = var.asg_desired_capacity
      DesiredCapacity      = var.asg_desired_capacity
    })
  }
}

# 営業時間終了時にASGを停止（スケールイン）
resource "aws_scheduler_schedule" "asg_stop" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-asg-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_stop
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:autoscaling:updateAutoScalingGroup"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      AutoScalingGroupName = aws_autoscaling_group.main.name
      MinSize              = 0
      MaxSize              = 0
      DesiredCapacity      = 0
    })
  }
}

# ========================================
# RDS Master Scheduler
# ========================================

resource "aws_scheduler_schedule" "rds_master_start" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-rds-master-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_start
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.master.identifier })
  }
}

resource "aws_scheduler_schedule" "rds_master_stop" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-rds-master-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_stop
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.master.identifier })
  }
}

# ========================================
# RDS Replica Scheduler
# ========================================

resource "aws_scheduler_schedule" "rds_replica_start" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-rds-replica-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_start
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.replica.identifier })
  }
}

resource "aws_scheduler_schedule" "rds_replica_stop" {
  count      = var.enable_schedule ? 1 : 0
  name       = "${var.project_name}-rds-replica-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_stop
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.replica.identifier })
  }
}
