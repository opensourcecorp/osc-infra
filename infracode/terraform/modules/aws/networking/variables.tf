variable "is_osc_core" {
  description = "Whether the deployment represents core OSC infrastructure. Defaults to 'false' to prevent accidental misrepresenation."
  type        = bool
  default     = false
}

variable "name" {
  description = "Common value for resource name components"
  type        = string
}

variable "source_uri" {
  description = "URI to the source of the code that actually calls this module"
  type        = string
}
