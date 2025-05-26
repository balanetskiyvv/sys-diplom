
# Дипломная работа по профессии «Системный администратор» - Василий Баланецкий

# Содержание
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
# Выполнение работы
### Terraform
* [Инфраструктура](#infrastructure)
   * [Сеть](#network)
   * [Группы безопасности](#securitygroup)
   * [Сетевой балансировщик](#load-balancer)
   * [Резервное копирование](#snapshots)
### Ansible
* [Установка и настройка ansible](#ansiblecfg)
* [Веб-серверы NGINX](#webnginx)
* [Мониторинг](#zabbix)
* Логи
   * [Elasticsearch](#elasticsearch)
   * [Kibana](#kibana)
   * [Filebeat](#filebeat)

**Ссылки на ресурсы**
[Сайт](http://158.160.101.91/)
[Kibana](http://)
[Zabbix]()

---------

## <a id="Задача">Задача</a>
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git.

### <a id="Инфраструктура">Инфраструктура</a>
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

### <a id="Сайт">Сайт</a>
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте Target Group включите в неё две созданных ВМ.

2. Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.

4. Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### <a id="Мониторинг">Мониторинг</a>
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### <a id="Логи">Логи</a>
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### <a id="Сеть">Сеть</a>
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте Security Groups соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  bastion host. Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  ProxyCommand. Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через NAT-шлюз.

### <a id="Резервное-копирование">Резервное копирование</a>
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### <a id="Дополнительно>"Дополнительно</a>
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

# Выполнение работы

## Terraform

### <a id="infrastructure">Инфраструктура</a>

Поднимаем инфраструктуру в Yandex Cloud используя terraform.

В целях безопасности указываем `cloud id и folder id` через задание переменных подставляя свои ***id***.  
Далее проверяем конфигурацию командой `terraform plan`, сверяем корректность синтаксиса и планируемого исполнения.  
Запускаем процесс поднятия инфраструктуры командой `terrafrom apply`

<img width="437" alt="изображение" src="https://github.com/user-attachments/assets/c7a3743a-7488-49a7-b8e5-8a41b2949560" />

После завершения работы terraform проверяем в web консоли Yandex Cloud развернутую инфраструктуру.  
Серверы WEB-1 и WEB-2 созданы в разных зонах.

screen

### <a id="network">Сеть</a>
**VPC и подсети**

Создаем 1 VPC с внутренними и публичными подсетями, таблицу маршрутизации и NAT-шлюз для доступа к интернету виртуальным машинам, находящимся внутри сети за Бастионом, который будет выполнять роль JumpHost.

<img width="1313" alt="изображение" src="https://github.com/user-attachments/assets/512ee9bd-b844-4908-a0dc-bec6c2b12ad4" />

### <a id="securitygroup">Группы безопасности</a>

<img width="1398" alt="изображение" src="https://github.com/user-attachments/assets/374eff49-66e2-4427-b095-da13e1f0a5ea" />

**SG bastion** с открытым 22 портом для работы SSH

<img width="521" alt="изображение" src="https://github.com/user-attachments/assets/3e16bb43-1b5a-4352-8ec9-df4ee90f3db6" />

**SG LAN** с разрешением любого трафика между ВМ внутри сети

<img width="528" alt="изображение" src="https://github.com/user-attachments/assets/c6202cfb-415d-4f53-ab78-399282ea8d32" />

**SG WEB** с разрешением WEB траффика для клиентов и обмена пакетами с Zabbix Server через порт 10050

<img width="513" alt="изображение" src="https://github.com/user-attachments/assets/62f33f09-db66-4a64-97f9-7f2bbc06a049" />

**SG Kibana** с открытым портом 5601 для доступа с внешней сети к Frontend Kibana

<img width="508" alt="изображение" src="https://github.com/user-attachments/assets/6844f192-df86-4449-9ddf-0723b802ee0c" />

**SG Zabbix Server** с открытым портом 10051 и 80 для доступа с внешней сети к Frontend Zabbix и работы ZAbbix Agent

<img width="512" alt="изображение" src="https://github.com/user-attachments/assets/6b0236b4-fe52-4df4-9850-b221106e747f" />

**SG Elasticsearch** с открытым портом 9200 для сбора данных

<img width="549" alt="изображение" src="https://github.com/user-attachments/assets/b841efed-a1f5-4f69-a1b4-b7f79062e5e1" />

**SG Load Balancer**

<img width="645" alt="изображение" src="https://github.com/user-attachments/assets/f737b775-de00-4ee5-b544-ede50bef2fb9" />

### <a id="load-balancer">Сетевой балансировщик</a>
**Создаем Target Group**

<img width="495" alt="изображение" src="https://github.com/user-attachments/assets/ed73f7b9-db93-46c9-8a97-c5d6f9bec534" />

**Создаем Backend Group**

<img width="716" alt="изображение" src="https://github.com/user-attachments/assets/ab5adac3-51ce-459e-a195-220b0b3a33d3" />

<img width="928" alt="изображение" src="https://github.com/user-attachments/assets/f590b245-cf34-48ab-b599-1d3dd1cd4fda" />

**Создаем HTTP-router**

<img width="717" alt="изображение" src="https://github.com/user-attachments/assets/6637912f-c90a-47b1-aa3c-37c9b2b84d25" />

**Создаем Application Load Balancer**

для распределения трафика на веб-сервера. Указываем HTTP router, задаем listener тип AUTO, порт 80.

<img width="715" alt="изображение" src="https://github.com/user-attachments/assets/1710b829-a3de-4db4-a626-356ddb4e3298" />

**Карта балансировки**

<img width="1211" alt="изображение" src="https://github.com/user-attachments/assets/88aae47f-f463-4157-97f5-3809c76c4d4f" />

### <a id="snapshots">Резервное копирование</a>

Создаем в terraform блок с расписанием snapshots

<img width="735" alt="изображение" src="https://github.com/user-attachments/assets/6ee3c44a-787d-4de9-979b-869d1cb1f99d" />

Проверяем на следующий день что снимки создались по расписанию

<img width="1399" alt="изображение" src="https://github.com/user-attachments/assets/3785d72c-7d1b-48f0-9cdd-fd891e51caa7" />

<img width="1625" alt="изображение" src="https://github.com/user-attachments/assets/068d4714-2cde-47df-bca3-2a814e7118c7" />

## Ansible

### <a id="ansiblecfg">Установка и настройка ansible</a>

Устанавливаем **Ansible** на локальном мастер хосте и настраиваем его работу через **bastion**

**файлы конфигурации**

ansible.cfg
```
[defaults]
inventory = ./hosts.ini
host_key_checking = False
```

**файл inventory**

Создаем файл hosts.ini с использованием FQDN имен ВМ вместо ip адресов
```
[all:vars]
ansible_ssh_user=balanetskiyvv
ansible_ssh_private_key_file=/Users/vasiliybalanetskiy/.ssh/id_ed25519
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q balanetskiyvv@158.160.33.144"'
  
[webservers]
web-1 ansible_host=web-1.ru-central1.internal
web-2 ansible_host=web-2.ru-central1.internal
  
[logservers]
elastic_srv ansible_host=elasticvm.ru-central1.internal
kibana_srv ansible_host=kibana-host.ru-central1.internal

[monitoring]
zabbix_srv ansible_host=zabbix-server.ru-central1.internal
```

**Проверяем доступность ВМ используя утилиту ping**

<img width="1012" alt="изображение" src="https://github.com/user-attachments/assets/46faf49e-0924-4d7b-89b8-cccbd2622f4a" />

### <a id="webnginx">Веб-серверы NGINX</a>

**Установка NGINX**

<img width="1014" alt="изображение" src="https://github.com/user-attachments/assets/edf92d1e-8840-405a-9ffe-bac8cc368812" />

проверяем доступность сайта в браузере по публичному ip адресу Load Balancer

<img width="506" alt="изображение" src="https://github.com/user-attachments/assets/1ec95230-2559-4498-b141-78755720cf73" />

делаем запрос `curl -v http://158.160.186.208:80`

<img width="876" alt="изображение" src="https://github.com/user-attachments/assets/95686229-ec90-4488-bd50-25b87251e7fd" />

проверяем работу Load Balancer в веб консоли YC, при изменении backend_ip убеждаемся что балансировщик работает

<img width="741" alt="изображение" src="https://github.com/user-attachments/assets/ea3eb435-2c80-4823-91f9-b410c97a22b2" />

### <a id="zabbix">Мониторинг</a>

**Установка Zabbix сервера**

Установливаем postgresql и создаем пользователя zabbix

<img width="1017" alt="изображение" src="https://github.com/user-attachments/assets/50b997d5-55a1-4e4f-a1b3-b1d4c6c3f791" />

Устанавливаем zabbix server

<img width="1012" alt="изображение" src="https://github.com/user-attachments/assets/9e44ba13-e092-4d26-afbf-2cb27cc59877" />

проверяем доступность frontend zabbix сервера

<img width="1018" alt="изображение" src="https://github.com/user-attachments/assets/41bb84e9-1826-4b7a-bb64-de4eda1bd2ef" />

**Устанавливаем Zabbix agent на веб-серверы**

<img width="821" alt="изображение" src="https://github.com/user-attachments/assets/373198c4-936e-44f4-98a2-d819d11a2023" />

Проверяем статус служб zabbix agent на web серверах

WEB-1
<img width="781" alt="изображение" src="https://github.com/user-attachments/assets/10aa0e99-e09b-428b-b274-8ef69e1ce906" />

WEB-2
<img width="784" alt="изображение" src="https://github.com/user-attachments/assets/77656d4e-0eb1-4d06-85dc-ed0878291f5f" />

Добавляем хосты используя FQDN имена в zabbix сервер и настраиваем дашборды

<img width="1501" alt="изображение" src="https://github.com/user-attachments/assets/f1591dc7-63b2-4feb-92b5-2916354a34cb" />

<img width="1485" alt="изображение" src="https://github.com/user-attachments/assets/d7d7cc61-7836-4514-a8da-fa8c98c7204e" />

<img width="1482" alt="изображение" src="https://github.com/user-attachments/assets/defcbc1c-353c-4fcb-80eb-3f5d847ea562" />

## Логи

### <a id="elasticsearch">Elasticsearch</a>

**Устанавливаем Elasticsearch**

<img width="1016" alt="изображение" src="https://github.com/user-attachments/assets/cdd40640-8f5b-4607-ba4c-7df8a9158067" />

Проверяем статус Elasticsearch

<img width="1011" alt="изображение" src="https://github.com/user-attachments/assets/bffba47b-81ad-4a17-8690-926303d162a3" />

### <a id="kibana">Kibana</a>

**Устанавливаем Kibana**

<img width="1016" alt="изображение" src="https://github.com/user-attachments/assets/d450a155-a734-4210-835b-b7f4d38acb19" />

Проверяем статус Kibana

<img width="1010" alt="изображение" src="https://github.com/user-attachments/assets/437c03fe-03fd-4497-ab01-f6015f03ae13" />

<img width="1680" alt="изображение" src="https://github.com/user-attachments/assets/6bbe925a-cb3f-4896-8450-89d09dd1cf3c" />

<img width="1003" alt="изображение" src="https://github.com/user-attachments/assets/baa23a2a-4986-4550-8f21-b3fdcabfb9d8" />

### <a id="filebeat">Filebeat</a>

**Устанавливаем Filebeat**

<img width="1016" alt="изображение" src="https://github.com/user-attachments/assets/8f9b77ae-9998-4743-abd5-e89b870727b4" />

Проверяем статус filebeat на веб-серверах

WEB-1
<img width="1003" alt="изображение" src="https://github.com/user-attachments/assets/77340e0a-bb35-4a21-8ddc-9381cce29959" />

<img width="999" alt="изображение" src="https://github.com/user-attachments/assets/6cde1cc9-559e-4e58-ace4-dad4e9697632" />

WEB-2
<img width="1004" alt="изображение" src="https://github.com/user-attachments/assets/143cf19a-3c71-47a4-b9cd-536ca81bd22d" />

<img width="998" alt="изображение" src="https://github.com/user-attachments/assets/b0c4ce1d-9b2a-43ca-a147-6c2a541f0a3b" />

Проверяем что Filebeat отправляет логи веб-серверов в Elasticsearch

<img width="1679" alt="изображение" src="https://github.com/user-attachments/assets/728c6bda-76c2-4f99-be48-80814217bf62" />
