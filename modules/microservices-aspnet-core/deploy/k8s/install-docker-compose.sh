#!/bin/bash

# Create $HOME/tools directory
mkdir ~/tools
echo "export PATH=$PATH:$HOME/tools" >> ~/.bashrc

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o $HOME/tools/docker-compose
chmod +x $HOME/tools/docker-compose

# Check installation
echo 
echo docker-compose installed.
echo
echo run the following command to enable docker-compose in the PATH
echo "source ~/.bashrc"
echo
