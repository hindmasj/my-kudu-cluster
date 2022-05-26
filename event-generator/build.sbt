
name := "event-generator"

version := "0.1"

scalaVersion := "2.13.8"

libraryDependencies ++= Seq(
  "org.apache.logging.log4j" %% "log4j-api-scala" % "12.0",
  "org.apache.logging.log4j" % "log4j-core" % "2.17.1",
  "org.scalatest" %% "scalatest" % "3.2.11" % Test,
  "com.fasterxml.jackson.dataformat" % "jackson-dataformat-yaml" % "2.13.3",
  "com.typesafe" % "config" % "1.4.2"
)
