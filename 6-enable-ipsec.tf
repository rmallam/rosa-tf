resource "null_resource" "enable_ipsec" {
  count = var.enable-ipsec == "true" ? 1 : 0
  provisioner "local-exec" {
    command = "scripts/enable-ipsec.sh"
    environment = {
      secret  = "${var.cluster_name}-credentials"
      cluster = var.cluster_name
    }
  }
  depends_on = [
    null_resource.cluster_seed
  ]
}