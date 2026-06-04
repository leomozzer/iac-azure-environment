locals {
  region_short = {
    eastus     = "eus"
    westeurope = "weu"
  }

  region_code = local.region_short[var.region]
  base        = "${var.purpose}-${local.region_code}-${var.instance}"
}
