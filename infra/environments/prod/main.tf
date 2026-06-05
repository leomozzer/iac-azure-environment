module "naming" {
  source   = "../../modules/naming"
  purpose  = var.purpose
  region   = var.region
  instance = var.instance
}
