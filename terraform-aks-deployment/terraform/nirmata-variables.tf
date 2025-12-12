#############################################
# Nirmata Configuration Variables
#############################################

variable "nirmata_token" {
  description = "Nirmata API token for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nirmata_url" {
  description = "Nirmata API URL"
  type        = string
  default     = "https://nirmata.io"
}

variable "nirmata_cluster_name" {
  description = "Name to register the cluster in Nirmata"
  type        = string
  default     = "aks-novartis-dev"
}

variable "nirmata_cluster_type" {
  description = "Nirmata cluster type (default-add-ons, etc.)"
  type        = string
  default     = "default-add-ons"
}

variable "enable_nirmata" {
  description = "Enable Nirmata integration"
  type        = bool
  default     = false  # Set to true to enable Nirmata
}

