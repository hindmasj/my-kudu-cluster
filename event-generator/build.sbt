
name := "event-generator"

version := "0.1"

scalaVersion := "2.13.10"

libraryDependencies ++= Seq(
  "org.apache.logging.log4j" %% "log4j-api-scala" % "12.0",
  "org.apache.logging.log4j" % "log4j-core" % "2.17.1",
  "org.scalatest" %% "scalatest" % "3.2.11" % Test,
  "org.yaml" % "snakeyaml" % "1.32",
  "com.typesafe" % "config" % "1.4.2"
)
