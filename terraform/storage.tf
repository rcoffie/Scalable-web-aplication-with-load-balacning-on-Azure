

# Local variables for file paths
locals {
  web_directory   = "${path.module}/web"
  index_html_path = "${local.web_directory}/index.html"
  error_html_path = "${local.web_directory}/404.html"
}

# Verify files exist
resource "null_resource" "verify_files" {
  provisioner "local-exec" {
    command = "bash -c 'if [ ! -f ./web/index.html ]; then echo \"Error: ./web/index.html does not exist\"; exit 1; fi; if [ ! -f ./web/404.html ]; then echo \"Error: ./web/404.html does not exist\"; exit 1; fi'"
  }
}


# Create resource group
resource "azurerm_resource_group" "static_website" {
  name       = "static-website-rg"
  location   = "eastus"
  depends_on = [null_resource.verify_files]
}

# Create storage account
resource "azurerm_storage_account" "static_website" {
  name                     = "staticwebsite${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.static_website.name
  location                 = azurerm_resource_group.static_website.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
}

# Configure static website
resource "azurerm_storage_account_static_website" "static_website" {
  storage_account_id = azurerm_storage_account.static_website.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# Create random string for unique storage account name
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Upload index.html
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static_website.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = local.index_html_path

  depends_on = [
    azurerm_storage_account_static_website.static_website,
    null_resource.verify_files
  ]
}

# Upload 404.html
resource "azurerm_storage_blob" "error_html" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.static_website.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = local.error_html_path

  depends_on = [
    azurerm_storage_account_static_website.static_website,
    null_resource.verify_files
  ]
}

# Output the website endpoint
output "website_endpoint" {
  value = azurerm_storage_account.static_website.primary_web_endpoint
}

# Output the storage account name
output "storage_account_name" {
  value = azurerm_storage_account.static_website.name
}

# Output the file paths for verification
output "file_paths" {
  value = {
    index_html = local.index_html_path
    error_html = local.error_html_path
  }
}