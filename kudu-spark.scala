// Commands to set up a kudu context in spark

import org.apache.kudu.client._
import org.apache.kudu.spark.kudu._
import collection.JavaConverters._

val kudumaster="172.31.160.1:7051,172.31.160.1:7151,172.31.160.1:7251"

val kuduContext = new KuduContext(
	kudumaster, spark.sparkContext)