
name := "event-generator"

version := "0.1"

scalaVersion := "2.13.4"

libraryDependencies ++= Seq(
  "org.apache.logging.log4j" %% "log4j-api-scala" % "12.0",
  "org.apache.logging.log4j" % "log4j-core" % "2.17.0",
  "org.scalatest" %% "scalatest" % "3.2.2" % Test,
  "com.fasterxml.jackson.dataformat" % "jackson-dataformat-yaml" % "2.6.7",
  "com.typesafe" % "config" % "1.4.1"
)
