#!/bin/bash

# set vars
WORK_DIR=$(cd ~ && pwd)

# Prepare to deploy
sudo apt update
sudp apt install git -y

# Deploy app
cd $WORK_DIR
if [ -d $WORK_DIR/reddit ]; then
    rm -rf $WORK_DIR/reddit && git clone https://github.com/Otus-DevOps-2017-11/reddit.git; else
    git clone https://github.com/Otus-DevOps-2017-11/reddit.git
fi

cd reddit && bundle install
puma -d
ps aux | grep puma
