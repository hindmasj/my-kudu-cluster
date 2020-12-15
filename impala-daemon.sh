#!/bin/bash

docker run -d --name kudu-impala --network="docker_default" \
  -p 21000:21000 -p 21050:21050 -p 25000:25000 -p 25010:25010 -p 25020:25020 \
  --memory=4096m apache/kudu:impala-latest impala
