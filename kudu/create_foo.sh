#/usr/bin/env bash

MASTERS=kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251
CONTAINER=kudu-master

docker exec -it ${CONTAINER} kudu table create ${MASTERS} '{
	"table_name": "foo",
	"schema": {
		"columns": [
			{"column_name":"id","column_type":"INT32"},
			{"column_name":"value","column_type":"STRING"}
		],
		"key_column_names": [ "id" ]
	},
	"partition": {
		"range_partition": {
			"columns": [ "id" ],
			"range_bounds": [
				{
					"upper_bound":{"bound_type":"exclusive","bound_values":["2000"]},
					"lower_bound":{"bound_type":"inclusive","bound_values":["1000"]}
				},
				{
					"upper_bound":{"bound_type":"exclusive","bound_values":["1000"]},
					"lower_bound":{"bound_type":"inclusive","bound_values":["0"]}
				}
			]
		}
	},
	"num_replicas":3
}'
