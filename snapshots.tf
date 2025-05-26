resource "yandex_compute_snapshot_schedule" "dipsnap" {
  name = "dipsnap"
  description = "Everyday, term 7 days"

  schedule_policy {
    expression = "0 1 * * *"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "retention-snapshot"
  }

  disk_ids = [
    "${yandex_compute_disk.disk-bastion.id}",
    "${yandex_compute_disk.disk-web-1.id}",
    "${yandex_compute_disk.disk-web-2.id}",
    "${yandex_compute_disk.disk-elastic.id}",
    "${yandex_compute_disk.disk-zabbix.id}",
    "${yandex_compute_disk.disk-kibana.id}"
  ]

  depends_on = [ 
    yandex_compute_instance.bastion,
    yandex_compute_instance.web-1,
    yandex_compute_instance.web-2,
    yandex_compute_instance.elasticvm,
    yandex_compute_instance.zabbix-server,
    yandex_compute_instance.kibana-host
   ]

}