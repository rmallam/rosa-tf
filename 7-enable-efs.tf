# https://cloud.redhat.com/experts/rosa/aws-efs/

resource "aws_iam_policy" "rosa_efs_csi_policy_iam" {
  count       = var.enable-efs ? 1 : 0
  name        = "${var.cluster_name}-rosa-efs-csi"
  path        = "/"
  description = "AWS EFS CSI Driver Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:TagResource",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "rosa_efs_csi_role_iam" {
  count = var.enable-efs ? 1 : 0
  name  = "${var.cluster_name}-rosa-efs-csi-role-iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = [
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-operator",
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-controller-sa"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_efs_csi_role_iam_attachment" {
  count      = var.enable-efs ? 1 : 0
  role       = aws_iam_role.rosa_efs_csi_role_iam[0].name
  policy_arn = aws_iam_policy.rosa_efs_csi_policy_iam[0].arn
}

resource "aws_efs_file_system" "rosa_efs" {
  count          = var.enable-efs ? 1 : 0
  creation_token = "efs-token-1"
  encrypted      = true
  tags = {
    Name = "${var.cluster_name}-rosa-efs"
  }
}

data "aws_instances" "selected" {
  instance_tags = {
    cluster-name = var.cluster_name
  }
}

data "aws_security_groups" "selected" {
  filter {
    name   = "tag:cluster-name"
    values = ["${var.cluster_name}"]
  }
}
# # update the default sec group for the default machine pool nodes using a data lookup
resource "aws_vpc_security_group_ingress_rule" "enable_efs" {
  for_each = var.efs_mount_targets

  security_group_id = data.aws_security_groups.selected.id
  cidr_ipv4         = try(each.value.subnet_cidr, null)
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

# #create a mount target i each subnet
resource "aws_efs_mount_target" "efs_mount_worker" {
  for_each = var.efs_mount_targets

  file_system_id = aws_efs_file_system.rosa_efs[0].id
  subnet_id      = try(each.value.subnet_id, null)
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}
