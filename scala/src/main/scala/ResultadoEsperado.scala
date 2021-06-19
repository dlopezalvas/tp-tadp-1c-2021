import Color.Color
import LadoMoneda.{Cara, Cruz, LadoMoneda}
import Paridad.Paridad

/*trait TipoResultado{
  def factorDeGanancia :Int
}*/

/*case object Color extends TipoResultado {override def factorDeGanancia: Int = 2}
case object Paridad extends TipoResultado {override def factorDeGanancia: Int = 2}
case class Docena(val numero: Int) extends TipoResultado {override def factorDeGanancia: Int = 3}
case class Numero(val valor: Int) extends TipoResultado {override def factorDeGanancia: Int = 36}
case object LadoMoneda extends TipoResultado {override def factorDeGanancia: Int = 2}



case class ResultadoEsperado(tipoResultado: TipoResultado, val peso: Int = 1)

object ResultadosEsperados{

  val algomas = new ResultadoEsperado(Numero(9))
  val Rojo = new ResultadoEsperado(Color)
}

/*case object Rojo extends ResultadoEsperado(Color)
object Negro extends ResultadoEsperado(Color)

object Par extends ResultadoEsperado(Paridad)
object Impar extends ResultadoEsperado(Paridad)*/

def seCumple(resultadoEsperado: ResultadoEsperado): Boolean =
  resultadoEsperado match{
    case ResultadoEsperado(Color, _) => ???
  }

CaraCargada*/

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
