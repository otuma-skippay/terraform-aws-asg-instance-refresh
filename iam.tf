data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "AllowAccessToAutoScalingGroup"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:StartInstanceRefresh",
    ]

    resources = [
      "${data.aws_autoscaling_group.group.arn}",
      "${data.aws_autoscaling_group.group.arn}*",
    ]
  }

  statement {
    sid    = "AllowAccessToLaunchTemplate"
    effect = "Allow"

    actions = [
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:ModifyLaunchTemplate",
    ]

    resources = [
      "${data.aws_launch_template.template.arn}",
      "${data.aws_launch_template.template.arn}*",
    ]
  }

  statement {
    sid    = "AllowWritingToCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.refresh.function_name}:*",
    ]
  }

  statement {
    sid       = "AllowSSMGetParameter"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:*:parameter${var.ami_ssm_parameter}"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.lambda_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
  description        = "${var.lambda_role_description}"
}

resource "aws_iam_role_policy" "lambda" {
  name_prefix = "${var.lambda_role_name}"
  policy      = "${data.aws_iam_policy_document.lambda.json}"
  role        = "${aws_iam_role.lambda.id}"
}