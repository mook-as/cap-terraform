/*
output "aws-node-arn" {
   // value = aws_iam_role.aws-node.arn
   value = data.aws_iam_role.cluster_iam_role.arn
}
*/
output "aws-eks-cluster-endpoint" {
    value = aws_eks_cluster.aws.endpoint
}

output "aws-eks-cluster-certificate-authority-data" {
    value = aws_eks_cluster.aws.certificate_authority.0.data
}

output "eks-cluster-name" {
   value = aws_eks_cluster.aws.name
}

output "force-eks-dependency-id" {
    value = null_resource.force-wait-on-eks.id
}
