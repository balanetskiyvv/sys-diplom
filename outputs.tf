output "FQDN_bastion" {
  value = yandex_compute_instance.bastion.fqdn
}

output "FQDN_web-1" {
  value = yandex_compute_instance.web-1.fqdn
}

output "FQDN_web-2" {
  value = yandex_compute_instance.web-2.fqdn
}

output "FQDN_elastic" {
  value = yandex_compute_instance.elasticvm.fqdn
}

output "FQDN_zabbix" {
  value = yandex_compute_instance.zabbix-server.fqdn
}

output "internal_ip_address_zabbix_server" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.ip_address
}

output "FQDN_kibana" {
  value = yandex_compute_instance.kibana-host.fqdn
}