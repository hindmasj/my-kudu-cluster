# Quickstart

## Managing The Cluster

### Creating The Cluster

````
. ./set-ip.sh
./full-cluster.sh up -d
````

### Starting The Cluster

````
. ./set-ip.sh
./full-cluster.sh up -d
````

### Stopping The Cluster

````
./full-cluster.sh stop
````

### Deleting The Cluster

````
./full-cluster.sh down -v
````

# Impala

## Add Impala Shell To The Cluster

### Create

````
./impala-daemon.sh
./impala-shell.sh
````

### Start

````
docker start kudu-impala
./impala-shell.sh
````

### Stopping

````
docker stop kudu-impala
````

### Deleting

````
docker rm kudu-impala
````

## Impala Actions

### Partition By Hash

````
create table test (
	id string,
	yyyy int,
	mm int,
	dd int,
	value string,
	ts timestamp,
	primary key (id,yyyy,mm,dd)
)
partition by hash (yyyy,mm,dd) partitions 20
stored as kudu;
````

````
insert into test values ("abc123",2020,12,14,'hello',"2020-12-14T00:12:13");

select * from test;
````

### Partition By Range

````
create table test2 (
	id string,
	yyyy int,
	mm int,
	dd int,
	value int,
	ts timestamp,
	primary key (id,yyyy,mm,dd)
)
partition by range (yyyy,mm,dd) (
	partition value =(2020,12,14)
)
stored as kudu;

insert into test2 values ('hello',2020,12,14,0,'2020-12-14T12:34:56');

alter table test2 add range partition value = (2020,12,15);

insert into test2 values ('world',2020,12,15,0,'2020-12-15T12:34:56');
````

# Some Spark

## Adding Spark Shell To The Cluster

### Installing Spark Shell Locally

````
wget https://archive.apache.org/dist/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.6.tgz
sudo -i
cd /opt
tar xvfz <download dir>/spark-2.4.5-bin-hadoop2.6.tgz
ln -s spark-2.4.5-bin-hadoop2.6 spark-2
exit
````

````
./spark-shell.sh
````

Lovely for playing with Spark but what if we want to use a container?

### Create Custom Spark Docker Image

Use the [Big Data Europe](https://github.com/big-data-europe) image.

````
docker pull bde2020/spark-base
docker build -f Dockerfile-spark -t sjh/spark .
````

The image build requires the spark tgz file downloaded above. The base image uses a version of spark 3 built with
scala 2.12. By substituting the downloaded archive we get a version of spark 2.4.5 built with scala 2.11. The image starts 
a spark shell to the correct network, imports the Kudu-Spark API and creates a new "kuduContext" object.

### Running Spark Shell

This runs the above image as a one shot spark shell. Exiting the shell stops the container and the "--rm" switch cleans it up afterwards.

````
docker run -it --rm -e KUDU_IP=${KUDU_QUICKSTART_IP} sjh/spark
````

## Spark Actions

### Sanity Test

````
val df=spark.read.options(
	Map("kudu.master" -> kudumaster,"kudu.table" -> "impala::default.test2")
	).format("kudu").load
df.count

:quit
````

If you did the previous Impala actions then the answer should be 2.

