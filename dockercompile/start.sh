#!/bin/bash

docker pull ubuntu:latest
docker build -t dockercompile:latest .
docker run --rm -d -it -v $(pwd):/volume dockercompile:latest
