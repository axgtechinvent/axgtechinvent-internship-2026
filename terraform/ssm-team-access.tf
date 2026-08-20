# ==============================================================================
# TEAM ACCESS TO EC2 VIA SSM SESSION MANAGER
#
# Each teammate authenticates as themselves. Nobody holds a private key, no
# port 22 is open, and CloudTrail records who opened which session on which
# instance. To revoke someone you remove them from the group -- there is no
# shared secret to rotate.
#
# Cost: $0. Systems Manager on EC2 instances, IAM, and IAM Identity Center all
# carry no additional charge. The only line item here is CloudWatch Logs for
# session transcripts (section 5), which is optional.
# ==============================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = module.ec2.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ssm_team_access" {
  statement {
    sid       = "StartSessionOnProjectInstances"
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Project"
      values   = [var.project_name]
    }
  }

  # StartSession authorizes the session document as well as the target, so the
  # document needs its own statement (the tag condition above cannot apply to
  # it). Without this, StartSession returns AccessDenied.
  statement {
    sid       = "AllowSessionDocument"
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = [
      "arn:aws:ssm:*::document/SSM-SessionManagerRunShell",
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/SSM-SessionManagerRunShell",
    ]
  }

  # Each person may only kill or resume their OWN sessions, not a colleague's.
  # Session IDs are prefixed with the caller's name.
  #
  # NOTE: $${aws:username} is only populated for IAM users. Under IAM Identity
  # Center, swap the resource for "arn:aws:ssm:*:*:session/$${aws:userid}-*".
  statement {
    sid    = "ManageOwnSessions"
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession",
    ]
    resources = ["arn:aws:ssm:*:*:session/$${aws:username}-*"]
  }

  # Read-only discovery: needed to list managed nodes in the console and for
  # the CLI to resolve a target. Harmless on its own -- grants no access.
  statement {
    sid    = "DiscoverManagedInstances"
    effect = "Allow"
    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:DescribeInstanceProperties",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:GetDocument",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_team_access" {
  name        = "${var.project_name}-ssm-shell-access-${var.environment}"
  description = "Open a Session Manager shell on ${var.project_name} instances. No SSH, no key pairs."
  policy      = data.aws_iam_policy_document.ssm_team_access.json

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

variable "team_members" {
  description = "Existing IAM usernames that may open a shell on the app instances."
  type        = list(string)
  default     = []
}

resource "aws_iam_group" "ec2_operators" {
  name = "${var.project_name}-ec2-operators-${var.environment}"
}

resource "aws_iam_group_policy_attachment" "ec2_operators_ssm" {
  group      = aws_iam_group.ec2_operators.name
  policy_arn = aws_iam_policy.ssm_team_access.arn
}

resource "aws_iam_user_group_membership" "ec2_operators" {
  for_each = toset(var.team_members)

  user   = each.value
  groups = [aws_iam_group.ec2_operators.name]
}

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/${var.project_name}-sessions-${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences for ${var.project_name}"
    sessionType   = "Standard_Stream"

    inputs = {
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchStreamingEnabled  = true
      cloudWatchEncryptionEnabled = false
      idleSessionTimeout          = "20"

      # Everyone lands as the ssm-user OS account. CloudTrail still attributes
      # each session to the individual IAM identity, so you keep per-person
      # audit without managing OS users.
      #
      # To give each person their own OS user instead, set runAsEnabled = true,
      # tag each IAM user with SSMSessionRunAs = <os-username>, and create those
      # users on the box via user_data. Skipping that here on purpose: with
      # runAsEnabled = true and no tag, sessions fail to start.
      runAsEnabled = false

      shellProfile = {
        linux = "cd /home/ssm-user && bash -l"
      }
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

output "ssm_connect_command" {
  description = "What each teammate runs to get a shell."
  value       = "aws ssm start-session --target ${modules.ec2_instance_id}"
}

output "ec2_operators_group" {
  description = "Add teammates here to grant shell access."
  value       = aws_iam_group.ec2_operators.name
}