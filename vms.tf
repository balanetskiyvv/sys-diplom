#-----------------создаем bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  hostname    = "bastion" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-bastion.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}

#-----------------создаем веб-сервер 1
resource "yandex_compute_instance" "web-1" {
  name        = "web-1" #Имя ВМ в облачной консоли
  hostname    = "web-1" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!


  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-web-1.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_web-1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

#-----------------создаем веб-сервер 2
resource "yandex_compute_instance" "web-2" {
  name        = "web-2" #Имя ВМ в облачной консоли
  hostname    = "web-2" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-web-2.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_web-2.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]

  }
}

#-----------------создаем сервер elasticsearch
resource "yandex_compute_instance" "elasticvm" {
  name        = "elasticvm" #Имя ВМ в облачной консоли
  hostname    = "elasticvm" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-elastic.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.es_sg.id]

  }
}

#-----------------создаем zabbix server
resource "yandex_compute_instance" "zabbix-server" {
  name        = "zabbix-server" #Имя ВМ в облачной консоли
  hostname    = "zabbix-server" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-zabbix.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.zabbix_sg.id]
  }
}

#-----------------создаем kibana хост
resource "yandex_compute_instance" "kibana-host" {
  name        = "kibana-host" #Имя ВМ в облачной консоли
  hostname    = "kibana-host" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.disk-kibana.id}"
  }

  metadata = {
    user-data          = "${file("./cloud-init.yml")}"
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.kibana_sg.id]
  }
}

#-----------------создание hosts.ini
resource "local_file" "inventory" {
  content  = <<-XYZ
  [all:vars]
  ansible_ssh_user=balanetskiyvv
  ansible_ssh_private_key_file=/Users/vasiliybalanetskiy/.ssh/id_ed25519
  ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q balanetskiyvv@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
  
  [webservers]
  web-1 ansible_host=${yandex_compute_instance.web-1.fqdn}
  web-2 ansible_host=${yandex_compute_instance.web-2.fqdn}
  
  [logservers]
  elastic_srv ansible_host=${yandex_compute_instance.elasticvm.fqdn}
  kibana_srv ansible_host=${yandex_compute_instance.kibana-host.fqdn}

  [monitoring]
  zabbix_srv ansible_host=${yandex_compute_instance.zabbix-server.fqdn}
  XYZ
  filename = "./ansiblestaff/hosts.ini"
}
