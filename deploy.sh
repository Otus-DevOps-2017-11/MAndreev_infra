#!/bin/bash

# Prepare to deploy
sudo apt update
sudp apt install git -y

# Deploy app
cd $HOME
if [ -d $HOME/reddit ]; then
    rm -rf $HOME/reddit && git clone https://github.com/Otus-DevOps-2017-11/reddit.git; else
    git clone https://github.com/Otus-DevOps-2017-11/reddit.git
fi

cd reddit && bundle install
puma -d
ps aux | grep puma
