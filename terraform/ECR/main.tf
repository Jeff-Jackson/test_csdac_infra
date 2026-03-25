provider "aws" {
  region  = var.region
}

variable "region" {
  type = string
  default = "us-west-1"
}

variable "images" {
  type = list(string)
  default = [
      "muster_adi_connector",
      "muster_api_proxy",
      "muster_api_service",
      "muster_apic_connector",
      "muster_aws_connector",
      "muster_azure_ad_connector",
      "muster_azuread_decorator",
      "muster_azure_connector",
      "muster_azure_servicetags",
      "muster_decorator",
      "muster_ldap_decorator",
      "muster_docker",
      "muster_etcd",
      "muster_gcp_connector",
      "muster_github_connector",
      "muster_ldap_connector",
      "muster_o365_connector",
      "muster_operator",
      "muster_pxgrid_cloud_connector",
      "muster_ravpn_ztna_connector",
      "muster_ui_backend",
      "muster_ui",
      "muster_umbrella_fqdnconnector",
      "muster_umbrella_ilsconnector",
      "muster_user_analysis",
      "muster_vcenter_connector",
      "muster_zoom_connector",
      "muster_bee",
      "muster_envoy",
      "muster_fmc_adapter",
      "muster_asa_adapter",
      "muster_cii_connector",
  ]
  description = "CSDAC images"
}

variable "special_images" {
  type = list(string)
  default = [
      "muster_ui_base",
      "muster_bee_base",
      "muster_python_connector_base",
      "muster_go_connector_base",
      "windriver_base",
      "csdac_cosign",
  ]
  description = "CSDAC special images"
}

locals {
  repos_csdac = flatten(formatlist("csdac/%s", var.images))
  repos_special = flatten(formatlist("csdac_special/%s", var.special_images))
}

resource "aws_ecr_repository" "csdac" {
  for_each = toset(local.repos_csdac)
  name     = each.key
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName = "CSDAC"
    ResourceOwner = "SBG"
    CiscoMailAlias = "dbudko@cisco.com"
    DataTaxonomy = "CustomerData+AdministrativeData"
    EnvironmentName = "csdac-dev"
    Environment = "dev"
    Terraform = "true"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csdac_special" {
  for_each = toset(local.repos_special)
  name     = each.key
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName = "CSDAC"
    ResourceOwner = "SBG"
    CiscoMailAlias = "dbudko@cisco.com"
    DataTaxonomy = "CustomerData+AdministrativeData"
    EnvironmentName = "csdac-dev"
    Environment = "dev"
    Terraform = "true"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "csdac_policy" {
  for_each = toset(local.repos_csdac)
  repository = aws_ecr_repository.csdac[each.value].name

  policy = jsonencode(
  {
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1000,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "deployed"
        ]
      },
      "description": "Keep all deployed images ",
      "rulePriority": 2
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1000,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "released"
        ]
      },
      "description": "Keep all released images",
      "rulePriority": 3
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "latest"
        ]
      },
      "description": "Keep latest tag",
      "rulePriority": 4
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "1.0.0-latest"
        ]
      },
      "description": "Keep 1.0.0-latest tag",
      "rulePriority": 5
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "1.1.0-latest"
        ]
      },
      "description": "Keep 1.1.0-latest tag",
      "rulePriority": 6
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "2.0.0-latest"
        ]
      },
      "description": "Keep 2.0.0-latest tag",
      "rulePriority": 7
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "2.1.0-latest"
        ]
      },
      "description": "Keep 2.1.0-latest tag",
      "rulePriority": 8
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "fmc7.4-latest"
        ]
      },
      "description": "Keep fmc7.4-latest tag",
      "rulePriority": 9
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "3.0.0-latest"
        ]
      },
      "description": "Keep 3.0.0-latest tag",
      "rulePriority": 10
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "3.0.1-latest"
        ]
      },
      "description": "Keep 3.0.1-latest tag",
      "rulePriority": 11
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "3.1.0-latest"
        ]
      },
      "description": "Keep 3.1.0-latest tag",
      "rulePriority": 12
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 1,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "3.2.0-latest"
        ]
      },
      "description": "Keep 3.2.0-latest tag",
      "rulePriority": 13
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 90,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "built"
        ]
      },
      "description": "Keep candidate images for 60 days",
      "rulePriority": 14
    },
    {
      "rulePriority": 15,
      "description": "Keep any tagged images for 14 days (PRs, inprogress images for integration testing, etc)",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": {
        "type": "expire"
      }
    }
  ]
})
}

output "csdac_repositories" {
  value = local.repos_csdac
}

output "special_repositories" {
  value = local.repos_special
}
