// Commands to set up a kudu context in spark

import org.apache.kudu.client._
import org.apache.kudu.spark.kudu._
import collection.JavaConverters._
import scala.sys.process._

sc.setLogLevel("INFO")

//val kuduhost = ("ip addr" #| "awk -f get-ip.awk" !!).trim
// val kuduhost = sys.env("KUDU_IP")
// println(kuduhost)
val kuduMasterStem="kudu-master-"
val kuduMasterArray=for(x <- 1 to 3) yield kuduMasterStem+x
val kuduPorts=Seq(7051,7151,7251)

val kudumaster=kuduMasterArray.zip(kuduPorts).map(x => s"${x._1}:${x._2}").mkString(",")

val kuduContext = new KuduContext(
	kudumaster, spark.sparkContext)