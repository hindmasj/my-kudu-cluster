# Quickstart

You need to clone the [Apache Kudu](https://github.com/apache/kudu.git) repo into the parent directory of this repository.

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
./local-spark-shell.sh
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
./spark-shell.sh
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

### Loading Spark Data

Create a test file with some dates in epoch millis. Use ````date -d 2020-12-14T01:23:45Z '+%s'```` for example. 
The result is in seconds so you need to add 3 zeroes to get milliseconds, which is what java will normally provide.

The load a dataframe from the file.

````
val df=spark.read.json("test-data.json")
df.show

+-----------+-------------+-----+
|         id|           ts|value|
+-----------+-------------+-----+
|test-item-1|1607898225000|  123|
|test-item-2|1608023594000|  456|
+-----------+-------------+-----+

import java.sql.Timestamp

df.map(r => new Timestamp(r.getAs[Long]("ts"))).show

+-------------------+
|              value|
+-------------------+
|2020-12-14 01:23:45|
|2020-12-15 09:13:14|
+-------------------+
````

### Diversion: Manipulating Time In Scala

Extract the YYYY, MM and DD fields from the epoch millis long ts field.

Using a java.util.Calendar

````
import java.util.Calendar

val c=Calendar.getInstance()
c.setTimeInMillis(1607898225000L)
c.get(Calendar.YEAR)
c.get(Calendar.MONTH)
c.get(Calendar.DAY_OF_MONTH)
````

Using java.time.Instant

````
import java.time._

val i = Instant.ofEpochMilli(1607898225000L)
val io=i.atOffset(ZoneOffset.UTC)
io.getYear
io.getMonthValue
io.getDayOfMonth
````

### Transforming The Timestamp

#### Row-wise Transform

Try to map the current row onto a new row with the extra fields merged in.

````
import java.time._
import org.apache.spark.sql._
import org.apache.spark.sql.types._

object dateUtil{

	val dateRowSchema = StructType(
		StructField("yyyy",IntegerType,false) ::
		StructField("mm",IntegerType,false) ::
		StructField("dd",IntegerType,false) ::
		Nil )

	def mergeDateFields(row0:Row):Row = {
		val ts = row0.getAs[Long]("ts")
		val tio = Instant.ofEpochMilli(ts).atOffset(ZoneOffset.UTC)
		val row1 = Row.apply( tio.getYear, tio.getMonthValue, tio.getDayOfMonth )
		Row.merge(row0,row1)
	}

}

val df1 = df.map(row => dateUtil.mergeDateFields(row))

<console>:58: error: Unable to find encoder for type org.apache.spark.sql.Row. 
An implicit Encoder[org.apache.spark.sql.Row] is needed to store org.apache.spark.sql.Row instances in a Dataset. 
Primitive types (Int, String, etc) and Product types (case classes) are supported by importing spark.implicits._  
Support for serializing other types will be added in future releases.
````

Sadly this does not work, as you cannot map one row to another. Notice also that the schema cannot be applied, which gives you the clue you are doing wrongly.

#### Column-wise Transform

This uses "withColumn" transform and makes use of the generic Spark sql functions. Note that the use of a temporary column to convert the millis time to a timestamp which is in seconds.

````
import org.apache.spark.sql.functions._

val df1 = df.withColumn("ts_sec",col("ts") / 1000 cast("timestamp")).
	withColumn("yyyy",year(col("ts_sec"))).
	withColumn("mm",month(col("ts_sec"))).
	withColumn("dd",dayofmonth(col("ts_sec"))).
	drop("ts_sec")
	
df1.show

+-----------+-------------+-----+----+---+---+
|         id|           ts|value|yyyy| mm| dd|
+-----------+-------------+-----+----+---+---+
|test-item-1|1607909025000|  123|2020| 12| 14|
|test-item-2|1608023594000|  456|2020| 12| 15|
+-----------+-------------+-----+----+---+---+
````