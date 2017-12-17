#!/bin/bash

# Set vars
USER=webapp
HOME_DIR=/home/$USER

# Install deps
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y git ruby-full ruby-bundler build-essential mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Check install
ruby -v
bundle -v
sudo systemctl status mongod

# Prepare
useradd $USER
mkdir -p $HOME_DIR && cd $HOME_DIR
git clone https://github.com/Otus-DevOps-2017-11/reddit.git
chown -R $USER:$USER $HOME_DIR

# Run app
cd reddit && bundle install
sudo -u $USER bash -c "puma -d"
ps aux | grep puma
