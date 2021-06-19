import Color.Color
import LadoMoneda.{LadoMoneda}
import Paridad.Paridad

abstract class ResultadoEsperado(val peso: Int = 1) {
  def factorGanacia :Int
}

case class ColorEsperado(val color: Color) extends ResultadoEsperado{ override def factorGanacia: Int = 2 }

case class ParidadEsperada(val paridad: Paridad) extends ResultadoEsperado{ override def factorGanacia: Int = 2 }

case class LadoEsperado(val ladoMoneda: LadoMoneda) extends ResultadoEsperado{
  override def factorGanacia: Int = 2;
}

case class Numero(val valor: Int) extends ResultadoEsperado { override def factorGanacia: Int = 36 }

case class Docena(val docena: Int) extends ResultadoEsperado { override def factorGanacia: Int = 3 }
