# Quickstart

## Managing The Cluster

### Creating The Cluster

````
. ./set-ip.sh
./full-cluster.sh up -d
./impala-daemon.sh
````

### Starting The Cluster

````
. ./set-ip.sh
./full-cluster.sh up -d
docker start kudu-impala
./impala-shell.sh
````

### Stopping The Cluster

````
docker stop kudu-impala
./full-cluster.sh stop
````

### Deleting The Cluster

````
docker rm kudu-impala
./full-cluster.sh down -v
````

## Some Impala

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

alter table test add range partition value = (2020,12,15);

insert into test2 values ('world',2020,12,15,0,'2020-12-15T12:34:56');
````

## Some Spark

### Adding Spark Shell

````
sudo -i
cd /opt
wget https://archive.apache.org/dist/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.6.tgz
tar xvfz spark-2.4.5-bin-hadoop2.6.tgz
ln -s spark-2.4.5-bin-hadoop2.6 spark-2
exit
````

### Running Spark Shell

````
./spark-shell.sh
````

Note the above commands imports the Kudu-Spark API and creates a new "kuduContext" object.

````
val df=spark.read.options(
	Map("kudu.master" -> kudumaster,"kudu.table" -> "impala::default.test2")
	).format("kudu").load
df.count
````
