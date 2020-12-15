// Commands to set up a kudu context in spark

import org.apache.kudu.client._
import org.apache.kudu.spark.kudu._
import collection.JavaConverters._

sc.setLogLevel("INFO")

val kuduhost="172.31.160.1"
val kuduports=Seq(7051,7151,7251)
val kudumaster=kuduports.map(kuduhost+":"+_).mkString(",")

val kuduContext = new KuduContext(
	kudumaster, spark.sparkContext)