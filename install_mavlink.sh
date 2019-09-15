#!/bin/bash

# Install Python 2.7+ or 3.3+.
sudo apt-get install python3-pip

# Install the future module
pip install --user future

# (Optionally) Install TkInter
sudo apt-get install python-tk

# Clone repo
git clone https://github.com/mavlink/mavlink.git
git submodule update --init --recursive

# Move to dir
cd mavlink/

# Compile with GCC
gcc -std=c99 -I ../../include/common -o mavlink_udp mavlink_udp.c

# Run
sh ./mavlink_udp
