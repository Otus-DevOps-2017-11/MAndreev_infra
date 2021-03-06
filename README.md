[![Build Status](https://travis-ci.org/Otus-DevOps-2017-11/MAndreev_infra.svg?branch=ansible-3)](https://travis-ci.org/Otus-DevOps-2017-11/MAndreev_infra)

# Infra
## Homework 5
#### 1. How to connect internalhost through bastion

```bash
* ssh 10.132.0.3 -o ProxyCommand="ssh -W %h:%p 35.205.76.161"
* ssh 10.132.0.3 -o ProxyCommand="ssh 35.205.76.161 nc %h %p 2> /dev/null"
* ssh -J 35.205.76.161 10.132.0.3
```
Using .ssh/config
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
Another examples
```
host internalhost
    hostname 10.132.0.3
    ProxyCommand ssh -W %h:%p bastion

host internalhost
    hostname 10.132.0.3
    ProxyCommand ssh bastion nc %h %p 2> /dev/null
```
#### 2. Host configuration.
```bash
Хост bastion, внешний IP: 35.205.76.161, внутренний IP: 10.132.0.2
Хост: internalhost, внутренний IP: 10.132.0.3
```
## Homework 6
#### Manual install:
* Install Ruby `config-scripts/install_ruby.sh`
* Install MongoDB `config-scripts/install_mongodb.sh`
* Deploy App `config-scripts/deploy.sh`

#### Auto install through [Google Cloud Platform](https://cloud.google.com/)
use this command to install app via google cli:
```bash
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --zone=europe-west1-d \
  --metadata-from-file startup-script=config-scripts/startup-script.sh
```
## Homework 7
#### Create image with HashiCorp Packer
```bash
packer build \
-var-file=variables.json \
immutable.json
```
#### Run reddit app
Use [Google Cloud Platform](https://cloud.google.com/)
```bash
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --zone=europe-west1-d
```
or run script
```bash
config-scripts/create-reddit-vm.sh
```
## Homework 8
#### Deploy reddit app using [GCP](https://cloud.google.com/) and [Terraform](https://www.terraform.io/)

This work shows how you can run two reddit-app instances from reddit-app image which we created at Homework 07  with HTTP load balancer without autoscale. Also you can see how to add several ssh-keys to the whole project. We have some files in terrafrom directory:
- `main.ft` - main terrafrom config file
- `outputs.tf` - is important data of attribute values (public IP addresses); this data is outputted when apply is called
- `variables.tf` - This defines some variables within our terraform configuration.
- `terraform.tfvars.example` - example for `terraform.tfvars` file with assigned variables; you should create `terraform.tfvars` in terraform directory yourself. It contains path to your ssh-keys, image family, project ID

To run app you should use this commands
```bash
terraform init # performs several different initialization steps in order to prepare a working directory for use
terraform plan # convenient way to check whether the execution plan for a set of changes matches your expectations without making any changes to real resources or to the state
terraform apply # apply the changes required to reach the desired state of the configuration, or the pre-determined set of actions generated by a `terraform plan` execution plan
```

## Homework 9
#### Add modules to a project

Now we separate environment: prod (ssh access from 5.16.0.0/14) and stage (ssh from everywhere) also use modules for each instance `reddit-app` and `reddit-db`
 - build instances

```bash
~/terraform/{prod | stage}$ terraform init
~/terraform/{prod | stage}$ terraform plan
~/terraform/{prod | stage}$ terraform apply
```
- add `storage-bucket.tf`

```bash
gsutil ls
gs://storage-bucket-test-93389695/
gs://storage-bucket-test2-2226613/
```

## Homework 10
#### Add ansible to `infra` project

- install ansible

```bash
brew install ansible
```
- add `ansible.cfg`

```bash
$ cat ansible.cfg 
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
```
- add different types for inventory file `inventory`, `inventory.yaml`, `inventory.json`
- test some commands to test and deploy `reddit-app`

```bash
ansible dbserver -m command -a uptime
ansible all -m ping
ansible all -m ping -i inventory.json
ansible app -m shell -a 'ruby -v; bundler -v'
ansible db -m command -a 'systemctl status mongod'
ansible db -m shell -a 'systemctl status mongod'
ansible db -m systemd -a name=mongod
ansible db -m service -a name=mongod
ansible app -m git -a 'repo=https://github.com/Otus-DevOps-2017-11/reddit.git dest=/home/appuser/reddit'
ansible app -m command -a 'git clone https://github.com/Otus-DevOps-2017-11/reddit.git dest=/home/appuser/reddit'
```
note: ansible==2.0 can't work with statick json inventory file; only dynamic

## Homework 11
#### Deploy and CM with [Ansible](https://www.ansible.com)
###### Todo list
- Using playbooks, handlers and templates for configuration environment and deploy stage app. One playbook, one script
- One playbook, several scripts
- Several playbooks
- Change provision packer's images from bash scripts to ansible playbooks

###### One playbook, one script
- we create one playbook for CM at all hosts `reddit_app_one_play.yml`
- add jinja2 template `mongod.conf` to `templates/`
- add `puma.service` unit to `files/`
- add `db_config.j2` to `files/`
- configure mongod at `reddit-db`

```bash
ansible-playbook reddit_app.yml --check --limit reddit-db -i inventory/gce.py # check playbook
ansible-playbook reddit_app.yml --limit reddit-db -i inventory/gce.py # apply playbook 
```
- configure `reddit-app` instance

```bash
ansible-playbook reddit_app.yml --check --limit reddit-app --tags app-tag -i inventory/gce.py # check
ansible-playbook reddit_app.yml --limit reddit-app --tags app-tag -i inventory/gce.py # apply playbook for reddit-app host with app-tag tag
```
- deploy app

```bash
ansible-playbook reddit_app.yml --check --limit reddit-app --tags deploy-tag -i inventory/gce.py # check 
ansible-playbook reddit_app.yml --check --limit reddit-app --tags deploy-tag -i inventory/gce.py # deploy reddit-app
```

###### One playbook, several script
- create `reddit_app_multiple_plays.yml`
- apply scripts

```bash
ansible-playbook reddit_app2.yml --tags db-tag -i inventory/gce.py # apply config db
ansible-playbook reddit_app2.yml --tags app-tag -i inventory/gce.py # apply config app instance
ansible-playbook reddit_app2.yml --tags deploy-tag -i inventory/gce.py # deploy app
```

###### Several playbooks
- create `db.yml`, `app.yml`, `deploy.yml` and `site.yml`

> `site.yml` is a main playbook which contains other playbooks

```bash
ansible-playbook site.yml -i inventory/gce.py --check # check
ansible-playbook site.yml -i inventory/gce.py # apply config instances and deploy rediit-app
```

###### Change provision packer's images from bash scripts to ansible playbooks
- Create `packer_app.yml` and `packer_db.yml`
- Change provisioners in `packer/app.json` and `packer/db.json`

```bash
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json
```

###### Add dynamyc inventory script
I found only one possibility for getting a dynamic list of hosts [here](http://docs.ansible.com/ansible/latest/intro_dynamic_inventory.html)
- install apache-libcloud

```bash
pip install apache-libcloud
```
- copy `gce.py` and `gce.ini` from https://github.com/ansible/ansible/tree/devel/contrib/inventory to ansible/inventory directory
- create a [Service Account](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount)
- download JSON credential to `ansible/inventory/` 
- edit gce.ini

```
gce_service_account_email_address = # Service account email found in ansible json file
gce_service_account_pem_file_path = # Path to ansible service account json file
gce_project_id = # Your GCE project name
```
- check `gce.py` script

```bash
inventory/gce.py --list | python -m json.tool
```

## Homework 12
#### [Ansible](https://www.ansible.com): working with roles and evironment
- move playbooks to separate roles
- create prod and stage environment
- using jdauphant.nginx role
- using dynamic inventory for ansible
- add [TravisCI](https://travis-ci.org) commits check

#### Roles
- create roles `app` and `db`

```bash
ansible-galaxy init app
ansible-galaxy init db
```
- move `tasks`, `handlers`, `templates` and `files` to roles 
- add variables to `roles/{db | app}/defaults/main.yml `
- add roles to `app.yml` and `db.yml`

#### Environments
- move `inventory` to `environtents/{stage | prod}`
- add default inventory file, `roles_path` and enable diff to `ansible.cfg`

```
[defaults]
inventory = ./environments/stage/gce.py
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
roles_path = ./roles
retry_files_enabled = False

[diff]
always = True
context = 5
```
- create `grop_vars` dir into environments/{stage | prod}
- add move variables from playbooks to `environments/{stage | prod}/group_vars/{app | db}`
> for dynamic inventory  should use `tag_reddit-app` and `tag_reddit-db`
- add env var to `{stage | prod}/group_vars/all`

```
env: prod
env: stage
```
- add info about environment into `roles/{app | db}/tasks/main.yml`

```yml
---
# tasks file for app
- name: Show info about the env this host belongs to
  debug:
  msg: "This host is in {{ env }} environment"
```
- move all playbooks to `ansible/playbooks`
- move other files to `ansible/old`

#### Using community role `jdauphant.nginx`
- add requirements environments/{stage | prod}/requirements.yml`
- install `jdauphant.nginx` role 

```
ansible-galaxy install -r environments/stage/requirements.yml
```
- add `nginx` viriables to proxy `environments/{stage | prod}/group_vars/app`
- change port from 9292 to 80 in terraform app module `terraform/modules/app/main.tf`
- add `jdauphant.nginx` to `app.yml`
- check instances

```
terraform init
terraform destroy
terraform apply -auto-approve=false
ansible-playbook playbooks/site.yml --check
ansible-playbook playbooks/site.yml
```
> before `terraform init` should remove `.terrafrom` directory

- add `.travis.yml` to check commits

## Homework 13
- learn ansible roles test with vagrant, molecula, testinfra
- add Vagrantfile for deploy add
- add mongo_db test
