resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "random_pet" "azurerm_user_assigned_identity_name" {
  prefix = "uami"
}

data "http" "myip" {
  url = "https://ident.me" // "https://api.ipify.org"
}

resource "azurerm_user_assigned_identity" "aks" {
  location            = azurerm_resource_group.main.location
  name                = random_pet.azurerm_user_assigned_identity_name.id
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}



resource "azurerm_kubernetes_cluster" "main" {
  count                         = var.create_aks_cluster ? 1 : 0
  location                      = azurerm_resource_group.main.location
  name                          = azurecaf_name.main.results["azurerm_kubernetes_cluster"]
  resource_group_name           = azurerm_resource_group.main.name
  dns_prefix                    = random_pet.azurerm_kubernetes_cluster_dns_prefix.id
  public_network_access_enabled = true
  tags                          = var.tags
  
#   identity {
#     type = "SystemAssigned"
#   }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
    tags       = var.tags
  }
  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")
      #   key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  api_server_access_profile {
    # Allow the current client's public IP address only
    authorized_ip_ranges = ["${chomp(data.http.myip.response_body)}/32"]
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
}

resource "azurerm_container_registry" "main" {
  name                = azurecaf_name.main.results["azurerm_container_registry"]
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  sku = "Standard"
  admin_enabled = true

}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}


output "client_certificate" {
  #   value     = azurerm_kubernetes_cluster.main[count.index] > 0 ? azurerm_kubernetes_cluster.main[count.index].kube_config.0.client_certificate : "no cert"
  value     = length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kube_config.0.client_certificate : null
  sensitive = true
}

output "kube_config" {
  value     = length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kube_config_raw : null
  sensitive = true
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.main.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}
