#-----------------считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "disk-bastion" {
  name = "disk-vm-bastion"
  type = "network-hdd"
  zone = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 10
}

resource "yandex_compute_disk" "disk-web-1" {
  name = "disk-vm-web-1"
  type = "network-hdd"
  zone = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 10
}

resource "yandex_compute_disk" "disk-web-2" {
  name = "disk-vm-web-2"
  type = "network-hdd"
  zone = "ru-central1-b"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 10
}

resource "yandex_compute_disk" "disk-elastic" {
  name = "disk-vm-elastic"
  type = "network-hdd"
  zone = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 15
}

resource "yandex_compute_disk" "disk-zabbix" {
  name = "disk-vm-zabbix"
  type = "network-hdd"
  zone = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 10
}

resource "yandex_compute_disk" "disk-kibana" {
  name = "disk-vm-kibana"
  type = "network-hdd"
  zone = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
  size = 10
}