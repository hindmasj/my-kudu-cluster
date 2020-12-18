// Commands to set up a kudu context in spark

import org.apache.kudu.client._
import org.apache.kudu.spark.kudu._
import collection.JavaConverters._
import scala.sys.process._

sc.setLogLevel("INFO")

//val kuduhost = ("ip addr" #| "awk -f get-ip.awk" !!).trim
val kuduhost = sys.env("KUDU_IP")
println(kuduhost)
val kuduports=Seq(7051,7151,7251)
val kudumaster=kuduports.map(kuduhost+":"+_).mkString(",")

val kuduContext = new KuduContext(
	kudumaster, spark.sparkContext)