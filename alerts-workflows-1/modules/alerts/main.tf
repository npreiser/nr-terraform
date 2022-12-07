terraform {
  required_version = "~> 1.1"
  required_providers {
     newrelic = {
            source  = "newrelic/newrelic"
            version = "~> 3.4.2"
        }
  }
}
# global variables, that come in from parent .tf file. 
variable "product" {}
variable "mvp_policy" {}
variable "account_id" {}  # account id that is passed in from above 

# create a condition in the policy specific to the product name(title) 
resource "newrelic_nrql_alert_condition" "compoundalert" {
  policy_id                      = var.mvp_policy
  name                           = "compoundalert_'${var.product.productId}'"
  aggregation_method             = "event_timer"
  violation_time_limit_seconds   = 259200
  aggregation_timer              = 60

  nrql {
     query = "SELECT count(*) from compoundalert where productId='${var.product.productId}'"
  }
  
   critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 60
    threshold_occurrences = "all"
   }
}



# create a channel instance of a pre-existing destination channel id from the json input. 
resource "newrelic_notification_channel" "mychannel" {
  account_id = var.account_id 
  name = "email-example"
  type = "EMAIL"
  destination_id = var.product.destinations[0].id  # dest id comes from the json input
  product = "IINT"

  property {
    key = "subject"
    value = "New Subject Title"
  }
}

# Build Workflow
resource "newrelic_workflow" "product_1_workflow" {
  name = "composite_alerthandler_'${var.product.productId}'"
  account_id = var.account_id 
  enrichments_enabled = false
  destinations_enabled = true
  enabled = true
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "by-condition"
    type = "FILTER"

    predicate {
      attribute = "conditionFamilyId"
      operator = "EXACTLY_MATCHES"
      values = [split(":",newrelic_nrql_alert_condition.compoundalert.id)[1]]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.mychannel.id
  }

}

output "debuginfo" {
  value = newrelic_nrql_alert_condition.compoundalert.id
}
