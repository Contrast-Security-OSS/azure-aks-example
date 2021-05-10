#Terraform `provider` section is required since the `azurerm` provider update to 2.0+
provider "azurerm" {

  # Using azurerm_client_config.client_config.object_id, implemented in 1.35.0
  version = ">=1.35.0"
  features {
  }
}

################
# RESOURCE GROUP
################

resource "azurerm_resource_group" "personal" {
  name     = "sales-engineering-${var.initials}"
  location = var.location

  tags = {
    CreatedBy             = data.azuread_user.current_user.display_name
  }
}

#############
# DATA VALUES
#############

# Bookkeeping - Lookup information for current user
data "azurerm_client_config" "client_config" {}
data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.client_config.object_id
}

#data "azurerm_key_vault_secret" "demo_db_username" {
#  name           = "DEMOSQLUSERNAME"
#  key_vault_id   = "/subscriptions/${data.azurerm_client_config.client_config.subscription_id}/resourceGroups/sales-engineering-demo/providers/Microsoft.KeyVault/vaults/azurecontrastdemovault"
#}

#data "azurerm_key_vault_secret" "demo_db_password" {
#  name          = "DEMOSQLPASSWORD"
#  key_vault_id   = "/subscriptions/${data.azurerm_client_config.client_config.subscription_id}/resourceGroups/sales-engineering-demo/providers/Microsoft.KeyVault/vaults/azurecontrastdemovault"
#}

data "azurerm_app_service_plan" "app" {
  name                = "se-app-service-plan-${azurerm_resource_group.personal.location}"
  resource_group_name = "sales-engineering-demo"
}

##########
# Database
##########

resource "random_password" "password" {
  length           = 25
  special          = true
  override_special = "_%@"
}

resource "azurerm_sql_firewall_rule" "database" {
  name                = "${replace(var.appname, "/[^-0-9a-zA-Z]/", "-")}-${var.initials}-firewall-rule"
  resource_group_name = azurerm_resource_group.personal.name
  server_name         = azurerm_sql_server.app.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_server" "app" {
  name                         = "${replace(var.appname, "/[^-0-9a-zA-Z]/", "-")}-${var.initials}-sql-server"
  resource_group_name          = azurerm_resource_group.personal.name
  location                     = azurerm_resource_group.personal.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = random_password.password.result

  tags = {
    CreatedBy                  = data.azuread_user.current_user.display_name
  }
}

resource "azurerm_sql_database" "app" {
  name                = "${replace(var.appname, "/[^-0-9a-zA-Z]/", "-")}-${var.initials}-sql-database"
  resource_group_name = azurerm_resource_group.personal.name
  location            = azurerm_resource_group.personal.location
  server_name         = azurerm_sql_server.app.name

  edition             = "Basic"

  tags = {
    CreatedBy         = data.azuread_user.current_user.display_name
  }
}


####################
# POLICY ASSIGNMENTS
####################

resource "azurerm_policy_assignment" "allowed_regions_assignment" {
  name                 = "allowed-regions-${var.initials}"
  location             = azurerm_resource_group.personal.location
  scope                = azurerm_resource_group.personal.id
  #policy_definition_id = azurerm_policy_definition.allowed_regions_policy.id
  policy_definition_id = "/subscriptions/4352f0e7-67db-4001-8352-25147175ee02/providers/Microsoft.Authorization/policyDefinitions/3259dade-deb4-42a5-bddc-a788a036134c"
  description          = "Policy Assignment created via an Acceptance Test"
  display_name         = "Azure Demo Policy: Allowed Regions"

  identity {
    type               = "SystemAssigned"
  }

  parameters = jsonencode({
    "allowedLocations": {
      "value": [var.location]
    }
  })
}

resource "azurerm_policy_assignment" "require_createdby_tag_rg" {
  name                 = "createdby-on-resources-groups${var.initials}"
  location             = azurerm_resource_group.personal.location
  scope                = azurerm_resource_group.personal.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Require CreatedBy tag on resources groups"
  display_name         = "Azure Demo Policy: Require CreatedBy tag on resource groups"

  identity {
    type               = "SystemAssigned"
  }

  parameters = jsonencode({
    "tagName": {
      "value":  "CreatedBy"
    }
  })
}

######################
# APP SERVICE AND PLAN
######################

resource "azurerm_app_service" "app" {
  name                = "${replace(var.appname, "/[^-0-9a-zA-Z]/", "-")}-${var.initials}-app-service"
  location            = azurerm_resource_group.personal.location
  resource_group_name = azurerm_resource_group.personal.name
  app_service_plan_id = data.azurerm_app_service_plan.app.id

  site_config {
    always_on = true
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                    = "Development"
    "CORECLR_ENABLE_PROFILING"                  = "1"
    "CORECLR_PROFILER"                          = "{8B2CE134-0948-48CA-A4B2-80DDAD9F5791}"
    "CORECLR_PROFILER_PATH_32"                  = "D:\\home\\SiteExtensions\\Contrast.NetCore.Azure.SiteExtension\\ContrastNetCoreAppService\\runtimes\\win-x32\\native\\ContrastProfiler.dll"
    "CORECLR_PROFILER_PATH_64"                  = "D:\\home\\SiteExtensions\\Contrast.NetCore.Azure.SiteExtension\\ContrastNetCoreAppService\\runtimes\\win-x32\\native\\ContrastProfiler.dll"
    "CONTRAST_DATA_DIRECTORY"                   = "D:\\home\\SiteExtensions\\Contrast.NetCore.Azure.SiteExtension\\ContrastNetCoreAppService\\runtimes\\win-x32\\native\\"
    "CONTRAST__API__URL"                        = data.external.yaml.result.url
    "CONTRAST__API__USER_NAME"                  = data.external.yaml.result.user_name
    "CONTRAST__API__SERVICE_KEY"                = data.external.yaml.result.service_key
    "CONTRAST__API__API_KEY"                    = data.external.yaml.result.api_key
    "CONTRAST__APPLICATION__NAME"               = var.appname
    "CONTRAST__SERVER__NAME"                    = var.servername
    "CONTRAST__SERVER__ENVIRONMENT"             = var.environment
    "CONTRAST__APPLICATION__SESSION_METADATA"   = var.session_metadata
    "CONTRAST__SERVER__TAGS"                    = var.servertags
    "CONTRAST__APPLICATION__TAGS"               = var.apptags
    "CONTRAST__AGENT__LOGGER__LEVEL"            = var.loglevel
    "CONTRAST__AGENT__LOGGER__ROLL_DAILY"       = "true"
    "CONTRAST__AGENT__LOGGER__BACKUPS"          = "30"

    # Individual DB
    "ConnectionStrings__DotNetFlicksConnection" = "Server=tcp:${azurerm_sql_server.app.name}.database.windows.net,1433;Initial Catalog=${azurerm_sql_database.app.name};Persist Security Info=False;User ID=${azurerm_sql_server.app.administrator_login};Password=${azurerm_sql_server.app.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  provisioner "local-exec" {
    command     = "./deploy.sh"
    working_dir = path.module

    environment = {
      webappname        = "${replace(var.appname, "/[^-0-9a-zA-Z]/", "-")}-${var.initials}-app-service"
      resourcegroupname = azurerm_resource_group.personal.name
    }
  }

  tags = {
    CreatedBy             = data.azuread_user.current_user.display_name
  }
}


resource "null_resource" "before" {
  depends_on = [azurerm_app_service.app]
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 40"
  }
  triggers = {
    "before" = "${null_resource.before.id}"
  }
}

resource "null_resource" "after" {
  depends_on = [null_resource.delay]
}

# CONTRAST AGENT
# --------------
# 1. Wait
# 2. Add agent
# 3. Restart app service

resource "azurerm_template_deployment" "extension" {
  name                = "template-extension-${azurerm_app_service.app.name}-${var.initials}"
  resource_group_name = azurerm_app_service.app.resource_group_name
  template_body       = file("arm_templates/siteextensions.json")

  parameters = {
    "siteName"          = azurerm_app_service.app.name
    "extensionName"     = "Contrast.NetCore.Azure.SiteExtension"
  }

  deployment_mode     = "Incremental"

  #wait until the app service starts before installing the extension
  depends_on = [null_resource.delay]

  #restart the app service after installing the extension
  provisioner "local-exec" {
    command     = "az webapp restart --name ${azurerm_app_service.app.name} --resource-group ${azurerm_app_service.app.resource_group_name}"
  }

}

resource "null_resource" "restart" {
  provisioner "local-exec" {
    command     = "az webapp restart --name ${azurerm_app_service.app.name} --resource-group ${azurerm_app_service.app.resource_group_name}"
  }
  triggers = {
    "before" = "${azurerm_template_deployment.extension.id}"
  }
}

###############
# MISCELLANEOUS
###############

#Extract the connection from the normal yaml file to pass to the app container
data "external" "yaml" {
  program = [var.python_binary, "${path.module}/parseyaml.py"]
}
