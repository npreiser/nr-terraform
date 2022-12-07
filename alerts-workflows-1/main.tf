terraform {
  required_version = "~> 1.1"
  required_providers {
     newrelic = {
            source  = "newrelic/newrelic"
            version = "~> 3.4.2"
        }
  }
}
# fill IN INFO HERE 
provider "newrelic" {
  region = "US"
  account_id =  ""    # <<<----- Account Number HERE ----> 
  api_key = ""     # <<<-----  API KEY HERE ----> 
}

variable "account_id" {
  type = string
  default = ""   # <<<----- Account Number HERE ----> 
}

# Variables
locals {
  products = jsondecode(file("${path.module}/inputs/trim_cfg_short.json"))
}

# create a single policy to hold all conditions
resource "newrelic_alert_policy" "policy" {
  name                = "Compound Alert MVP"
  incident_preference = "PER_CONDITION"
}
# Each product, passing the product and the corresponding dashboard config
module "product" {
  # convert array to map,  
   for_each = {
    for p in local.products : p.title => p
   }
   source = "./modules/alerts"

   mvp_policy = newrelic_alert_policy.policy.id
   product = each.value 
   account_id = var.account_id

 }