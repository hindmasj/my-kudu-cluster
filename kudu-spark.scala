// Commands to set up a kudu context in spark

import org.apache.kudu.client._
import org.apache.kudu.spark.kudu._
import collection.JavaConverters._
import scala.sys.process._

sc.setLogLevel("INFO")

// Build a list of masters and ports
val prefix="my-kudu-cluster_kudu-master-"
val suffix="_1"
val kuduMasterArray=Seq("kudu-master") ++: {for(x <- 1 to 2) yield prefix+x+suffix}
val kuduPorts=Seq(7051,7151,7251)

// docker inspection of the master addresses
val cmd="docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "
val sq="'"
//val kuduMasterAddresses=for(x <- kuduMasterArray) yield {cmd+x}.!!.trim.stripPrefix(sq).stripSuffix(sq)

// Are we local or in a container
val defaultIP="0.0.0.0"
val ip=try {
    sys.env("SPARK_LOCAL_IP")
} catch {
    case e:java.util.NoSuchElementException => defaultIP
}
val (kuduMasterURL,kc) = ip match {

    case `defaultIP` => {
        print("In a container\n")
        // Master URL and context for container based shell
        val kuduContainerList=kuduMasterArray.zip(kuduPorts).map(x => s"${x._1}:${x._2}")
        val kuduContainerURL=kuduContainerList.mkString(",")
        (kuduContainerURL,new KuduContext(kuduContainerURL,sc))
    }

    case _ => {
        print("In a host\n")
        // Master URL and context for local shell
        val kuduLocalList=for(x <- kuduPorts) yield s"${ip}:${x}"
        val kuduLocalURL=kuduLocalList.mkString(",")
        (kuduLocalURL,new KuduContext(kuduLocalURL,sc))
    }

}

sc.setLogLevel("WARN")
