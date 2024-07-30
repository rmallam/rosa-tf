resource "aws_security_group" "expose_api_sg" {
  count = var.expose_api == "true" ? 1 : 0

  name        = "${var.cluster_name}-api-sg"
  description = "Allow traffic from outside VPC to kubernetes api over private link"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-api-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "expose_api_sg" {
  count = var.expose_api == "true" ? 1 : 0

  security_group_id = aws_security_group.expose_api_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "null_resource" "expose_api" {
  count = var.expose_api == "true" ? 1 : 0
  provisioner "local-exec" {
    command = "scripts/expose-api.sh"
    environment = {
      sg_id   = aws_security_group.expose_api_sg[0].id
      cluster = var.cluster_name
    }
  }
  depends_on = [
    null_resource.cluster_seed
  ]
}