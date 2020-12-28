# Docker Cluster For Kafka

Based on the docker work of [Wurstmeister](https://github.com/wurstmeister).

## Running The Cluster

````
./kafka-cluster.sh up -d
````

To shut it down use "stop", to destroy it use "down -v".

## Command Line Client

Use an instance of the same kafka image to access the client tools.

````
./kafka-shell.sh

kafka-topics.sh --bootstrap-server kafka:9092 --create --topic test
Created topic test.

kafka-topics.sh --bootstrap-server kafka:9092 --list
test

kafka-topics.sh --bootstrap-server kafka:9092 --describe
Topic: test     PartitionCount: 1       ReplicationFactor: 1    Configs: segment.bytes=1073741824
        Topic: test     Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001

exit
````

## Publish And Consume Some Messages

The kafka distro comes with a tool to create a load of random test messages.

````
kafka-verifiable-producer.sh --bootstrap-server kafka:9092 --topic test --repeating-keys 1000 --max-messages 1000
````

Now consume them back again.

````
kafka-verifiable-consumer.sh --bootstrap-server kafka:9092 --topic test --group-id test-consumer
````

## Spark Streaming

There are confusingly two different guides. One for [Streaming](https://spark.apache.org/docs/2.4.5/streaming-kafka-0-10-integration.html) 
and one for [Structured Streaming](https://spark.apache.org/docs/2.4.5/structured-streaming-kafka-integration.html). The initial difference is that
streaming requires the "spark-streaming-kafka" package and structured requires the "spark-sql-kafka" package. We are only considering structured streaming here.

With everything else running start a spark-shell container (see the [Kudu](../README.md) guide) in a new console.
 
````
sc.setLogLevel("warn")

val df = spark.readStream.format("kafka").option("kafka.bootstrap.servers","kafka:9092").
     option("subscribe","test").
     option("startingOffsets","earliest").
     load()
	 
df.writeStream.format("console").start()
````

Then in the other console start using the producer tool to generate more messages. You can observe them progressing in the spark window.

Ctrl-C will stop the process (and kill your spark shell).