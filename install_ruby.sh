#!/bin/bash

echo "Install ruby"
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential

echo "Check install"
ruby -v
bundle -v
