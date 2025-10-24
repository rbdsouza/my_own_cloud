variable "lan_host" {
  description = "Base domain used for Traefik routers"
  type        = string
  default     = "edgebox.local"
}

variable "timezone" {
  description = "Timezone for containers"
  type        = string
  default     = "UTC"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "changeme"
  sensitive   = true
}
