# Quickstart

## Building The Images

````
./refresh_images
````

## Managing The Cluster

How to use Docker to create your cluster.

### Creating/Starting The Cluster

````
./full-cluster.sh up -d
./full-cluster.sh logs -f
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
docker exec -it kudu-master kudu master list kudu-master-0:7051

Configuration error: Could not connect to the cluster: no leader master found. 
Client configured with 1 master(s) (kudu-master-0:7051) but cluster indicates it expects 3 master(s) 
(kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251)

docker exec -it kudu-master kudu master list kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251

               uuid               |    rpc-addresses    |   role
----------------------------------+---------------------+----------
 1179a46f94ab4dd98038c009340517e1 | 172.19.227.131:7051 | FOLLOWER
 b721afbcfad44014b764c617e065c9b7 | 172.19.227.131:7151 | LEADER
 14ec7c9f0c6a43f89d99e6145dfa5c5d | 172.19.227.131:7251 | FOLLOWER
 
docker exec -it kudu-master kudu cluster ksck kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251 
 ````

See the script ``kudu/create_foo.sh`` for an example of how to create a table from the command line.

````
kudu/create_foo.sh

docker exec -it kudu-master kudu table list kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251

foo
````

# Impala

An Impala daemon is started as part of the existing cluster. You need to wait about 2 minutes after 
starting the cluster before the daemon is fully up and connected to the storage cluster.

## Running Impala

The script ``impala-shell.sh`` connects to the impala container and runs the impala-shell, passing 
in any extra commands required. Note that as this is running inside the container you have to get creative 
if you are working with files.

### Interactive Prompt

To get an Impala prompt run the script ``impala-shell.sh``.
````
./impala-shell.sh

create table foo (id int primary key, value string) partition by hash partitions 2 stored as kudu;
insert into foo values (1,'hello');
select * from foo;
exit;
````

Now there is a new table, with the prefix indicating it is an Impala table in the "default" database.

````
docker exec -it kudu-master kudu table list kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251

foo
impala::default.foo
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

Use the ``docker cp`` command to copy the file to the Impala user's home directory.

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

This table will be used in the Spark examples below.

# Some Spark

When using either of the methods for accessing a spark shell shown below, the start up sequence create the
following useful objects for you.

 * kuduMasterURL: String
 * kuduContext: org.apache.kudu.spark.kudu.KuduContext
 * kuduBuilder: org.apache.kudu.client.KuduClient$KuduClientBuilder
 * kuduClient: org.apache.kudu.client.KuduClient

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

Then use this script to run the shell. The script includes setting up a string to use as the master URL
and a KuduContext object. Look for the objects ``kuduMasterURL`` and ``kc``.

````
./local-spark-shell.sh
````

We can try using the Kudu client to work with our new table.

````
import scala.collection.JavaConversions._

val tablesList = kuduClient.getTablesList
for(t <- tablesList.getTablesList) {println(t)}
````

If you were using scala 2.13+ (which you cannot yet with Spark), the above loop would look like

````
import scala.jdk.CollectionConverters._
...
for(t <- tablesList.getTablesList.asScala) {println(t)}
````

You can use the Kudu Spark context too.

````
kuduContext.tableExists("impala::default.test2")
val kuduRDD = kuduContext.kuduRDD(sc,"impala::default.test2")
kuduRDD.count
val kuduRDD = kuduContext.kuduRDD(sc,"impala::default.test2",Seq("id","value","ts"))
kuduRDD.take(10).foreach(println)

res2: Boolean = true
kuduRDD: org.apache.spark.rdd.RDD[org.apache.spark.sql.Row] = KuduRDD[0] at RDD at KuduRDD.scala:48
res3: Long = 2
[hello,0,2020-12-14 12:34:56.0]
[world,0,2020-12-15 12:34:56.0]
````

### Create Custom Spark Docker Image

The image uses the [Big Data Europe](https://github.com/big-data-europe) image as a base. 
The resulting image is built when you run the ``refresh-images.sh`` script.

The image build requires the spark tgz file downloaded above. The base image uses a version of spark 3 
built with scala 2.12. By substituting the downloaded archive we get a version of spark 2.4.5 built with 
scala 2.11. The image starts a spark shell to the correct network, imports the Kudu-Spark API and creates a 
new "kuduContext" object.

### Running Spark Shell

This runs the above image as a one shot spark shell. Exiting the shell stops the container and the "--rm" 
switch cleans it up afterwards.

````
./spark-shell.sh
````

This shell creates the same string and KuduContext objects as above.

## Spark Actions

You can also perform the kuduClient test as shown above.

### Sanity Test Reading A Data Frame

````
val df=spark.read.options(
	Map("kudu.master" -> kuduMasterURL,"kudu.table" -> "impala::default.test2")
	).format("kudu").load
df.count

:quit
````

If you did the previous Impala actions then the answer should be 2.

### Loading Spark Data

Create a test file with some dates in epoch millis. Use 
````date -d 2020-12-14T01:23:45Z '+%s'```` for example. 
The result is in seconds so you need to add 3 zeroes to get milliseconds, which is what java will normally 
provide.

A version of this file has been copied to the container for you. Load a dataframe from the file.

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

### Writing The Data To The Table

Now add the extra year, month and day columns. See the discussion below for why we do it this way.
The other column types have to be coerced into matching the Impala data types. This could be avoided by
using a schema. See the next section.

````
import org.apache.spark.sql.functions._

val df1 = df.withColumn("ts_sec",col("ts") / 1000 cast("timestamp")).
	withColumn("yyyy",year(col("ts_sec")) cast "int").
	withColumn("mm",month(col("ts_sec")) cast "int").
	withColumn("dd",dayofmonth(col("ts_sec")) cast "int").
	withColumn("value",col("value") cast "int").
    withColumn("ts",col("ts") * 1000).
	drop("ts_sec")
	
df1.show
````

Write the data frame to the table "test2".

````
kuduContext.insertRows(df1,"impala::default.test2")
````

### Writing The Data With Schemas

Create a schema for the loaded data. Note that we define the timestamp as a bigint, not a timestamp
as we still need to manipulate it to convert from a millisecond, then seconds, and then to
microseconds.

````
import org.apache.spark.sql.types._

val loadedSchema = StructType( Array(
  StructField("id",StringType,false),
  StructField("ts",LongType,false),
  StructField("value",IntegerType,false)
))

val df=spark.read.schema(loadedSchema).json("test-data.json")
````

Again, extract the extra values and convert the timestamp to microseconds.

````
import org.apache.spark.sql.functions._

val df1 = df.
    withColumn("ts_sec",col("ts") / 1000 cast("timestamp")).
	withColumn("yyyy",year(col("ts_sec"))).
	withColumn("mm",month(col("ts_sec"))).
	withColumn("dd",dayofmonth(col("ts_sec"))).
    withColumn("ts",col("ts") * 1000).
    drop("ts_sec")
````

Now write to the table. This time we are writing with the same keys as before, so we need to "upsert".

````
kuduContext.upsertRows(df1,"impala::default.test2")
````
    
## Spark Discussion

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
An implicit Encoder[org.apache.spark.sql.Row] is needed to store org.apache.spark.sql.Row instances in a 
Dataset. 
Primitive types (Int, String, etc) and Product types (case classes) are supported by importing 
spark.implicits._  
Support for serializing other types will be added in future releases.
````

Sadly this does not work, as you cannot map one row to another. Notice also that the schema cannot be 
applied, which gives you the clue you are doing wrongly.

#### Column-wise Transform

This uses "withColumn" transform and makes use of the generic Spark sql functions. Note that the use of a 
temporary column to convert the millis time to a timestamp which is in seconds.

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
