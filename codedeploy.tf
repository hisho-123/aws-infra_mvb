# ========================================
# CodeDeploy Application
# ========================================

resource "aws_codedeploy_app" "backend" {
  compute_platform = "Server"
  name             = "${var.project_name}-backend"

  tags = {
    Name = "${var.project_name}-backend"
  }
}

# ========================================
# CodeDeploy Deployment Group
# ========================================

resource "aws_codedeploy_deployment_group" "backend" {
  app_name               = aws_codedeploy_app.backend.name
  deployment_group_name  = "${var.project_name}-backend-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  autoscaling_groups = [aws_autoscaling_group.main.name]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = {
    Name = "${var.project_name}-backend-dg"
  }
}
