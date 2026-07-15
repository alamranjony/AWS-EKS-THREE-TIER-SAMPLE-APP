# Managed node groups without a custom launch template have their EC2
# instances' ENIs attached to EKS's auto-generated "cluster security
# group" (module.eks.cluster_security_group_id), not to the
# `eks_nodes` security group created in modules/network. The rule in
# modules/network sourcing from that custom SG is effectively a no-op
# for real node traffic unless a launch template is added later to
# attach it explicitly. This is the rule that actually matters today -
# it has to live here rather than inside modules/network, since it
# needs an output from modules/eks, which doesn't exist until the
# cluster itself is created.
resource "aws_security_group_rule" "database_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = module.network.database_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
  description               = "MySQL from EKS managed node group (auto-generated cluster SG)"
}
