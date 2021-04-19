# Quickstart

## Managing The Cluster

How to use Docker to create your cluster.

### Creating The Cluster

````
./full-cluster.sh up -d
````

### Starting The Cluster

````
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

# Kudu

## Web Sites

You can access the cluster web sites at any of the mapped ports. See the compose file 
``kudu-cluster.yml`` for details, but the simplest method is to point your browser at 
``localhost:8051`` to connect to the first master server, and then follow the links from there.

## Command Line

To use the Kudu command line you should execute it from the first master container which is called 
"kudu-master". The kudu master list is always "kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251".

````
docker exec -it kudu-master kudu table list kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251

foo
impala::default.foo
````

See the script ``kudu/create_foo.sh`` for an example of how to create a table from the command line.

# Impala

An Impala daemon is started as part of the existing cluster. You need to wait about 2 minutes after 
starting the cluster before the daemon is fully up and connected to the storage cluster.

## Running Impala

The script ``impala-shell.sh`` connects to the impala container and runs the impala-shell, passing 
in any extra commands required. Note that as this running inside the container you have to get creative 
if you are working with files.

### Interactive Prompt

To get an Impala prompt run the script ``impala-shell.sh``.
````
./impala-shell.sh

create table foo (id int primary key, value string) partition by hash partitions 2 stored as kudu;
insert into foo values (1,'hello');
select * from foo;
drop table foo;
exit;
````

### Query Command

You can run queries from the command line as normal.

````
./impala-shell.sh -q 'create table foo (id int primary key, value string) 
partition by hash partitions 2 stored as kudu;'
````

Be careful of mixed quoting.

````
 ./impala-shell.sh -q 'insert into foo values (1,'hello')'

ERROR: AnalysisException: Could not resolve column/field reference: 'hello'
````

````
./impala-shell.sh -q 'insert into foo values (1,"hello")'

Modified 1 row(s), 0 row error(s) in 0.13s
````

### Query File

If you have to run queries from a file you need to copy the file to the container first.

````
echo "select * from foo;" > test-foo.sql
./impala-shell.sh -f test-foo.sql

Could not open file 'test-foo.sql': [Errno 2] No such file or directory: 'test-foo.sql'
````

````
docker cp test-foo.sql kudu-impala:/home/impala
./impala-shell.sh -f test-foo.sql
 
+----+-------+
| id | value |
+----+-------+
| 1  | hello |
+----+-------+
Fetched 1 row(s) in 0.16s
````

### Output File

If you want the result written to an output file you need to do the reverse and copy the result file back
out of the container.

````
./impala-shell.sh -f test-foo.sql -B --output_delimiter=',' -o foo.txt
docker cp kudu-impala:/home/impala/foo.txt .
cat foo.txt

1,hello
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
