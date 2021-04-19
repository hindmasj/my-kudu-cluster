#/usr/bin/env bash

MASTERS=kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251
CONTAINER=kudu-master

docker exec -it ${CONTAINER} kudu table delete ${MASTERS} foo;