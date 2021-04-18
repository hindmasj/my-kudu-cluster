package home.hindmasj.event_generator

import scala.util.Random

object DataUtils {

  def randomIpv4():String = {
    val range=256
    val bytes:Seq[Int]=for(_ <- 1 to 4) yield randomInt(range)
    bytes.mkString(".")
  }

  val DEFAULT_STRING_LEN = 12

  def randomString():String = {
    randomString(DEFAULT_STRING_LEN)
  }

  def randomString(length:Int):String = {
    Random.alphanumeric.take(length).mkString
  }

  def randomInt(): Int={
    Random.nextInt()
  }

  def randomInt(range:Int):Int = {
    Random.nextInt(range)
  }
}
