import Color.Color
import com.sun.net.httpserver.Authenticator.Success
import jdk.internal.dynalink.support.DefaultInternalObjectFilter
import Tipos._
import scala.util.{Success, Try}

case object Prueba {

  def materia: String = "tadp"

}

object Color extends Enumeration{
  type Color = Value
  val Rojo, Negro = Value
}



trait ResultadoEsperado {
  def obtenerFactorPara(resultado: Resultado) :Int = {
    if (esResultado(resultado)) return factorGanacia
    else 0
  }
  abstract def esResultado(resultado: Resultado) :Boolean
  abstract def factorGanacia :Int
}

case class ColorEsperado(val color: Color) extends ResultadoEsperado{
  override def esResultado(resultado: Resultado): Boolean = resultado match{
    case Numero(_,_color) => return _color == color
  }

  override def factorGanacia: Int = 2
}


case class Docena(val docena: Int) extends ResultadoEsperado{
  override def esResultado(resultado :Resultado): Boolean = resultado match{
    case Numero(valor, _) => return valor/12 == docena - 1
  }
  override def factorGanacia: Int = 3
}

case class Paridad(val esPar: Boolean) extends ResultadoEsperado{
  override def esResultado(resultado :Resultado): Boolean = resultado match{
    case Numero(valor, _) => return (valor%2 == 0) == esPar
  }
  override def factorGanacia: Int = 2
}

val primerDocena = new Docena(1)
val segundaDocena = new Docena(2)
val tercerDocena = new Docena(3)

abstract case class Resultado()
case class Numero(val valor: Int, color: Option[Color]) extends Resultado with ResultadoEsperado {
  override def esResultado(resultado: Resultado): Boolean = resultado match{
    case Numero(_valor, _) => return _valor == valor
  }

  override def factorGanacia: Int = 36
}

val Cero = new Numero(0, None)
val Uno = new Numero(1, Some(Color.Rojo))
val Dos = new Numero(2, Some(Color.Negro))
val Tres = new Numero(3, Some(Color.Rojo))
val Cuatro = new Numero(4, Some(Color.Negro))
val Cinco = new Numero(5, Some(Color.Rojo))
val Seis = new Numero(6, Some(Color.Negro))
val Siete = new Numero(7,Some(Color.Rojo))
val Ocho = new Numero(8, Some(Color.Negro))
val Nueve = new Numero(9, Some(Color.Rojo))
val Diez = new Numero(10, Some(Color.Negro))
val Once = new Numero(11, Some(Color.Negro))
val Doce = new Numero(12, Some(Color.Rojo))
val Trece = new Numero(13, Some(Color.Negro))
val Catorce = new Numero(14, Some(Color.Rojo))
val Quince = new Numero(15, Some(Color.Negro))
val Dieciseis = new Numero(16, Some(Color.Rojo))
//...
object Cara extends Resultado
object Cruz extends Resultado


object Tipos {
  type Dinero = Double
  type Jugada = Dinero => Resultado => Dinero
}

case class Apuesta(val dinero:Dinero, resultadoEsperado: ResultadoEsperado) extends (Resultado => Dinero){
  override def apply(resultado: Resultado): Dinero = resultadoEsperado.obtenerFactorPara(resultado) * dinero
}


case class JugarA(resultadoEsperado: ResultadoEsperado) extends Jugada{
  override def apply(monto: Dinero): Apuesta = new Apuesta(monto, resultadoEsperado)
}

