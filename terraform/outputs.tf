output "edgebox_services" {
  value = {
    api      = "http://api.${var.lan_host}"
    grafana  = "http://grafana.${var.lan_host}"
    signage  = "http://sign.${var.lan_host}"
    files    = "http://files.${var.lan_host}"
    portainer = "http://portainer.${var.lan_host}"
  }
}
