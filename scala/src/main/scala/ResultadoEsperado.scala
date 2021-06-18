import Color.Color
import LadoMoneda.{Cara, Cruz, LadoMoneda}
import Paridad.Paridad

/*trait TipoResultado{
  def factorDeGanancia :Int
}

case object Colorr extends TipoResultado {
  override def factorDeGanancia: Int = 2}

case class ResultadoEsperadoo(tipoResultado: TipoResultado, val peso: Int = 1)

object Resultados{
  val Rojo = ResultadoEsperadoo(Colorr)
  val CaraCargada = ResultadoEsperadoo(LadoMoneda, 4)
}


def seCumple(resultadoEsperado: ResultadoEsperadoo): Boolean =
  resultadoEsperado match{
    case ResultadoEsperadoo(Colorr, _) => ???
  }

CaraCargada*/

trait ResultadoEsperado {
  def factorGanacia :Int
}

case class ColorEsperado(val color: Color) extends ResultadoEsperado{ override def factorGanacia: Int = 2 }

case class ParidadEsperada(val paridad: Paridad) extends ResultadoEsperado{ override def factorGanacia: Int = 2 }

case class LadoEsperado(val ladoMoneda: LadoMoneda) extends ResultadoEsperado{ override def factorGanacia: Int = 2}

case class Numero(val valor: Int) extends ResultadoEsperado { override def factorGanacia: Int = 36 }

case class Docena(val docena: Int) extends ResultadoEsperado { override def factorGanacia: Int = 3 }