# Infra
## Homework 5
#### 1. Пример как подключиться к internalhost через bastion
В одну команду:
```
* ssh 10.132.0.3 -o ProxyCommand="ssh -W %h:%p 35.205.76.161"
* ssh 10.132.0.3 -o ProxyCommand="ssh 35.205.76.161 nc %h %p 2> /dev/null"
* ssh -J 35.205.76.161 10.132.0.3
```
Используя .ssh/config
```
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa
    UseKeychain yes
    ServerAliveInterval 30

host bastion
    hostname 35.205.76.161

host internalhost
    hostname 10.132.0.3
    proxyjump bastion
```
Ещё два, что указаны выше
```
host internalhost
    hostname 10.132.0.3
    ProxyCommand ssh -W %h:%p bastion

host internalhost
    hostname 10.132.0.3
    ProxyCommand ssh bastion nc %h %p 2> /dev/null
```
#### 2. Конфигурация и данные для подключения.
```
Хост bastion, внешний IP: 35.205.76.161, внутренний IP: 10.132.0.2
Хост: internalhost, внутренний IP: 10.132.0.3
```
## Homework 6
#### Manual install:
* Install Ruby `scripts/install_ruby.sh`
* Install MongoDB `scripts/install_mongodb.sh`
* Deploy App `scripts/deploy.sh`

#### Auto install through [Google Cloud Platform](https://cloud.google.com/)
use this command to install app via google cli:
```
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --zone=europe-west1-d \
  --metadata startup-script-url=https://raw.githubusercontent.com/Otus-DevOps-2017-11/MAndreev_infra/master/startup-script.sh
```
