package home.hindmasj.event_generator

import org.scalatest.BeforeAndAfter
import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.must.Matchers.{a, convertToAnyMustWrapper}

class DataUtilsTest extends AnyFunSuite with BeforeAndAfter {

  test ("Can generate random string") {
    assert (DataUtils.randomString().length == DataUtils.DEFAULT_STRING_LEN)
  }

  test("Can generate random string of specific length"){
    val testLen=7
    assert(DataUtils.randomString(testLen).length == testLen)
  }

  test("Can generate random integer"){
    DataUtils.randomInt() mustBe a[Int]
  }

  test("Can generate random number in specific range"){
    val testRange=256
    val value=DataUtils.randomInt(testRange)
    value mustBe a[Int]
    assert(value >= 0)
    assert(value < testRange)
  }

  test("Can generate random IPv4 address"){
    val value=DataUtils.randomIpv4()
    assert(value matches """[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}""")
  }

}
