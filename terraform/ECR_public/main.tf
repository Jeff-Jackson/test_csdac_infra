provider "aws" {
  region  = "us-east-1"
}

variable "public_images" {
  type = list(string)
  default = [
      "muster_python_connector_base",
      "muster_go_connector_base",
      "windriver_base",
      "muster_ui_base",
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
      "muster_ad_decorator",
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
      "muster_webex_connector",
      "muster_bee",
      "muster_envoy",
      "muster_fmc_adapter",
      "muster_umbrella_branchtointernet_connector",
      "csdac_cosign",
      "csdac_charts",
      "muster-custom-resources",
      "muster-operator",
      "muster-api-proxy",
      "muster_generic_text_connector",
      "muster_umbrella_privateappfqdn_connector",
      "muster_umbrella_usertogroup_connector",
      "muster_common_service_adapter_adapter",
      "muster_aws_object_connector",
      "muster_aws_servicetags_connector",
      "muster_cyber_vision_connector",
      "muster_cybervision_connector",
      "muster-cii-connector",
  ]
  description = "CSDAC public images"
}

locals {
  repos_csdac_public = flatten(var.public_images)
}

resource "aws_ecrpublic_repository" "csdac_public" {
  for_each = toset(local.repos_csdac_public)
  repository_name     = each.key
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName = "CSDAC"
    ResourceOwner = "SBG"
    CiscoMailAlias = "dbudko@cisco.com"
    DataTaxonomy = "CustomerData+AdministrativeData"
    EnvironmentName = "csdac-prod"
    Environment = "prod"
    Terraform = "true"
  }
}

output "csdac_public_repositories" {
  value = local.repos_csdac_public
}
