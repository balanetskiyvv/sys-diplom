
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
* [Инфраструктурв](#infrastructure)
* [Сеть](#network)
* [Группы безопасности](#securitygroup)
* [Сетевой балансировщик](#load-balancer)
* [Резервное копирование](#snapshots)

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

<img width="1609" alt="изображение" src="https://github.com/user-attachments/assets/673c90c3-e1dc-40dd-9daa-6bbd50b2f83b" />

### <a id="network">Сеть</a>
**VPC и подсети**

Создаем 1 VPC с внутренними и публичными подсетями, таблицу маршрутизации и NAT-шлюз для доступа к интернету виртуальным машинам, находящимся внутри сети за Бастионом, который будет выполнять роль JumpHost.

<img width="1609" alt="изображение" src="https://github.com/user-attachments/assets/6055ae9e-f0c9-4d70-a2ab-cdad8eb46b56" />

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

!!!!#!#
!!!!##!#!##xxxSCREEN проверки состояний load balncer

**Создаем HTTP-router**

<img width="717" alt="изображение" src="https://github.com/user-attachments/assets/6637912f-c90a-47b1-aa3c-37c9b2b84d25" />

**Создаем Application Load Balancer**

для распределения трафика на веб-сервера. Указываем HTTP router, задаем listener тип AUTO, порт 80.

<img width="715" alt="изображение" src="https://github.com/user-attachments/assets/1710b829-a3de-4db4-a626-356ddb4e3298" />

**Карта балансировки**

<img width="1211" alt="изображение" src="https://github.com/user-attachments/assets/88aae47f-f463-4157-97f5-3809c76c4d4f" />

### <a id="snapshots">Резервное копирование</a>

Создаем в terraform блок с расписанием snapshots

<img width="400" alt="изображение" src="https://github.com/user-attachments/assets/86148085-d2f6-42d3-9404-b5a975ad886a" />

