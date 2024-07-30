data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ebs" {
  description             = "KMS key for ebs volumes for cluster ${var.cluster_name}"
  deletion_window_in_days = 10
  tags = {
    "red-hat" : "true"
  }
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"

    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "etcd" {
  description             = "KMS key for etcd encryption for cluster ${var.cluster_name}"
  deletion_window_in_days = 10
  tags = {
    "red-hat" : "true"
  }
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}


module "rhcs_cluster_rosa_hcp" {
  source                             = "./modules/terraform-rhcs-rosa-hcp"
  cluster_name                       = var.cluster_name
  openshift_version                  = var.openshift_version
  oidc_config_id                     = var.oidc_config_id
  aws_subnet_ids                     = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  hack_subnet_id_machine_pool        = tolist(module.vpc.private_subnets)[0]
  kms_key_arn                        = resource.aws_kms_key.ebs.arn
  etcd_kms_key_arn                   = resource.aws_kms_key.etcd.arn
  private                            = var.private
  machine_cidr                       = var.machine_cidr
  service_cidr                       = var.service_cidr
  pod_cidr                           = var.pod_cidr
  host_prefix                        = var.host_prefix
  http_proxy                         = var.http_proxy
  https_proxy                        = var.https_proxy
  no_proxy                           = var.no_proxy
  additional_trust_bundle            = var.additional_trust_bundle
  properties                         = var.properties
  tags                               = var.tags
  wait_for_create_complete           = var.wait_for_create_complete
  etcd_encryption                    = var.etcd_encryption
  disable_waiting_in_destroy         = var.disable_waiting_in_destroy
  destroy_timeout                    = var.destroy_timeout
  upgrade_acknowledgements_for       = var.upgrade_acknowledgements_for
  replicas                           = var.replicas
  compute_machine_type               = var.compute_machine_type
  aws_availability_zones             = module.vpc.availability_zones
  autoscaler_max_pod_grace_period    = var.autoscaler_max_pod_grace_period
  autoscaler_pod_priority_threshold  = var.autoscaler_pod_priority_threshold
  autoscaler_max_node_provision_time = var.autoscaler_max_node_provision_time
  autoscaler_max_nodes_total         = var.autoscaler_max_nodes_total
  default_ingress_id                 = var.default_ingress_id
  default_ingress_listening_method   = var.default_ingress_listening_method
  path                               = var.path
  permissions_boundary               = var.permissions_boundary
  create_account_roles               = var.create_account_roles
  account_role_prefix                = var.account_role_prefix
  create_oidc                        = var.create_oidc
  managed_oidc                       = var.managed_oidc
  create_operator_roles              = var.create_operator_roles
  operator_role_prefix               = var.operator_role_prefix
  oidc_endpoint_url                  = var.oidc_endpoint_url
  machine_pools                      = var.machine_pools
  identity_providers                 = var.identity_providers
}

############################
# VPC
############################
module "vpc" {
  source = "./modules/terraform-rhcs-rosa-hcp/modules/vpc"

  name_prefix              = var.cluster_name
  availability_zones_count = var.replicas
}

