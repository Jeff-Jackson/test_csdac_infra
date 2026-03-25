terraform {
  required_version = ">= 0.13.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
}
