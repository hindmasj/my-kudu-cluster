# Creating Avro Messages

## Starting Spark Shell

````
/opt/spark/bin/spark-shell --packages org.apache.spark:spark-avro_2.11:2.4.5
````

## Creating A Message

* https://docs.oracle.com/database/nosql-12.1.3.0/GettingStartedGuide/avroschemas.html
* https://blog.knoldus.com/scala-kafka-avro-producing-and-consuming-avro-messages/

Create a generic record from the schema.

````
import scala.io.Source
import org.apache.avro._
import org.apache.avro.generic._

val schemaText = Source.fromFile("schema.avsc").getLines.mkString
val schema: Schema = new Schema.Parser().parse(schemaText)
val record1: GenericRecord = new GenericData.Record(schema)

record1.put("id","avro-rec1")
record1.put("value",234)
record1.put("ts",1607909025000L)
````

Create an Avro file from the record using the encoders.

````
import java.io._
import org.apache.avro.io._
import org.apache.avro.specific._

val writer = new SpecificDatumWriter[GenericRecord](schema)
val out = new FileOutputStream("message.avro")
val encoder = EncoderFactory.get().binaryEncoder(out, null)

writer.write(record1,encoder)
encoder.flush
out.close
````

You now have a file "message.avro" containing the data.

## Examining The Message With Avro Tools

````
wget https://downloads.apache.org/avro/avro-1.10.1/java/avro-tools-1.10.1.jar

java -jar avro-tools-1.10.1.jar fragtojson --schema-file schema.avsc message.avro

{
  "id" : "avro-rec1",
  "value" : 234,
  "ts" : 1607909025000
}
````
