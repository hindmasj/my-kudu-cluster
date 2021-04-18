docker exec -it docker_kudu-master-1_1 kudu table create \
	kudu-master-1:7051,kudu-master-2:7151,kudu-master-3:7251 \
'{
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
