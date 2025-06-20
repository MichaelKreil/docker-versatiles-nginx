#!/bin/bash

cd "$(dirname "$0")/../docker"

docker build --progress=plain -t versatiles-nginx:latest -f Dockerfile .