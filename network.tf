#-----------------создаем облачную сеть
resource "yandex_vpc_network" "main_vpc" {
  name = "diploma-vpc"
}

#-----------------создаем NAT для выхода в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "diploma-gateway"
  shared_egress_gateway {}
}

#-----------------создаем сетевой маршрут для выхода в интернет через NAT
resource "yandex_vpc_route_table" "rt" {
  name       = "diploma-route-table"
  network_id = yandex_vpc_network.main_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

#-----------------создаем подсети
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.0.0.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "subnet_web-1" {
  name           = "subnet_web-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "subnet_web-2" {
  name           = "subnet_web-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#-----------------создаем Target Group для веб-серверов
resource "yandex_alb_target_group" "diptarget-group" {
  name = "diptarget-group"

  target {
    subnet_id = yandex_vpc_subnet.subnet_web-1.id
    ip_address = yandex_compute_instance.web-1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet_web-2.id
    ip_address = yandex_compute_instance.web-2.network_interface.0.ip_address
  }

}

#-----------------создаем Backend Group и связываем с target group
resource "yandex_alb_backend_group" "dipbackend-group" {
  name = "dipbackend-group"

  http_backend {
    name = "dip-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.diptarget-group.id}"]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      interval = "10s"
      timeout = "2s"
      healthy_threshold = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }

}

#-----------------Создаем HTTP router
resource "yandex_alb_http_router" "diprouter" {
  name = "diprouter"
}

resource "yandex_alb_virtual_host" "dip-vhost" {
  name = "dip-vhost"
  http_router_id = yandex_alb_http_router.diprouter.id
  route {
    name = "backend-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.dipbackend-group.id
        timeout = "3s"
      }
    }
  }

}

#-----------------создаем сетевой балансировщик нагрузки
resource "yandex_alb_load_balancer" "dip-balancer" {
    name = "dip-balancer"
    network_id = yandex_vpc_network.main_vpc.id
    security_group_ids = [yandex_vpc_security_group.public-load-balancer.id, yandex_vpc_security_group.LAN.id]
    allocation_policy {
      location {
        zone_id = "ru-central1-a"
        subnet_id = yandex_vpc_subnet.private_subnet.id
      }
    }
    listener {
      name = "dip-listener"
      endpoint {
        address {
          external_ipv4_address {
          }
        }
        ports = [80]
      }
      http {
        handler {
          http_router_id = yandex_alb_http_router.diprouter.id
        }
      }
    }

}