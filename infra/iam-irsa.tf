locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
  ns_system         = "kube-system"
}

# Generic IRSA role creator
resource "aws_iam_role" "irsa_role" {
  for_each = {
    externaldns = {
      sa   = "external-dns"
      ns   = local.ns_system
      policy = data.aws_iam_policy_document.externaldns.json
    }
    alb = {
      sa   = "aws-load-balancer-controller"
      ns   = local.ns_system
      policy = data.aws_iam_policy_document.alb.json
    }
    fluentbit = {
      sa   = "fluent-bit"
      ns   = local.ns_system
      policy = data.aws_iam_policy_document.fluentbit.json
    }
  }

  name               = "${var.project_name}-irsa-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[each.key].json
  tags               = var.tags
}

data "aws_iam_policy_document" "irsa_assume" {
  for_each = {
    externaldns = {}
    alb = {}
    fluentbit = {}
  }
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${lookup({externaldns=local.ns_system, alb=local.ns_system, fluentbit=local.ns_system}, each.key)}:${lookup({externaldns="external-dns", alb="aws-load-balancer-controller", fluentbit="fluent-bit"}, each.key)}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "irsa_policy" {
  for_each = {
    externaldns = data.aws_iam_policy_document.externaldns.json
    alb         = data.aws_iam_policy_document.alb.json
    fluentbit   = data.aws_iam_policy_document.fluentbit.json
  }
  name   = "${var.project_name}-${each.key}-policy"
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "attach" {
  for_each = aws_iam_role.irsa_role
  role     = each.value.name
  policy_arn = aws_iam_policy.irsa_policy[each.key].arn
}

data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}
data "aws_iam_policy_document" "externaldns" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [data.aws_route53_zone.primary.arn]
  }
  statement {
    actions   = ["route53:ListHostedZones","route53:ListResourceRecordSets","route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "alb" {
  statement { actions = ["elasticloadbalancing:*","ec2:Describe*","ec2:Get*","iam:CreateServiceLinkedRole","cognito-idp:DescribeUserPoolClient","waf-regional:GetWebACLForResource","waf-regional:GetWebACL","waf-regional:AssociateWebACL","waf-regional:DisassociateWebACL","wafv2:GetWebACLForResource","wafv2:GetWebACL","wafv2:AssociateWebACL","wafv2:DisassociateWebACL","tag:GetResources","tag:TagResources","shield:DescribeSubscription","shield:GetSubscriptionState","shield:CreateProtection","shield:DeleteProtection","shield:DescribeProtection"], resources=["*"] }
}



data "aws_iam_policy_document" "fluentbit" {
  statement {
    actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogStreams","logs:PutRetentionPolicy"]
    resources = ["*"]
  }
}

