module "networking" {
  source = "../modules/aws/networking"

  name        = "osc"
  is_osc_core = true
  source_uri  = "https://github.com/opensourcecorp/infracode.git"
}
