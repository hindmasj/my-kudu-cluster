#!/bin/bash

docker exec -it -w /home/impala kudu-impala impala-shell "${@}"