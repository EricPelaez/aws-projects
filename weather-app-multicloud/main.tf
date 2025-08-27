# AWS provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

# Azure provider
provider "azurerm" {
  features {}
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# S3 bucket
resource "aws_s3_bucket" "weather_app" {
  bucket = "weather-tracker-app-bucket-ep"

  tags = {
    Name = "Weather Tracker App Bucket"
  }
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "weather_app" {
  bucket = aws_s3_bucket.weather_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Allow public access (turns off BlockPublicPolicy for this bucket)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.weather_app.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Upload website files
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.weather_app.id
  key          = "index.html"
  source       = "website/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "website_style" {
  bucket       = aws_s3_bucket.weather_app.id
  key          = "styles.css"
  source       = "website/styles.css"
  content_type = "text/css"
}

resource "aws_s3_object" "website_script" {
  bucket       = aws_s3_bucket.weather_app.id
  key          = "script.js"
  source       = "website/script.js"
  content_type = "application/javascript"
}

# Upload assets
resource "aws_s3_object" "website_assets" {
  for_each     = fileset("website/assets", "*")
  bucket       = aws_s3_bucket.weather_app.id
  key          = "assets/${each.value}"
  source       = "website/assets/${each.value}"
}

# Public read policy for website hosting
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.weather_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.weather_app.id}/*"
      }
    ]
  })
}


# Define Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-static-website"
  location = "East US"
}

# Define Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "mystorageaccountericp"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

# Upload index.html
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "$web"  # Static website container
  type                   = "Block"
  content_type           = "text/html"
  source                 = "website/index.html"  # Path to local file
}

# Upload styles.css
resource "azurerm_storage_blob" "styles_css" {
  name                   = "styles.css"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/css"
  source                 = "website/styles.css"  # Path to local file
}

# Upload script.js
resource "azurerm_storage_blob" "scripts_js" {
  name                   = "script.js"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/javascript"
  source                 = "website/script.js"  # Path to local file
}

# Upload all assets in the assets folder
resource "azurerm_storage_blob" "assets" {
  for_each = fileset("website/assets", "**/*")

  name                   = "assets/${each.value}"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = lookup(
    {
      "png"  = "image/png"
      "jpg"  = "image/jpeg"
      "jpeg" = "image/jpeg"
      "gif"  = "image/gif"
      "svg"  = "image/svg+xml"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
  source = "website/assets/${each.value}"  # Path to local assets
}


resource "aws_route53_zone" "main" {
  name = "weathertrackerproject.cloud"
}



resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.storage.id
  index_document     = "index.html"
  error_404_document = "error.html"
}