import Color.Color
import LadoMoneda.LadoMoneda
import Paridad.{Impar, Par}
import Tipos.Peso

trait Suceso {
  def peso() : Peso = 1;
  def cumpleCon(jugada : Jugada) : Boolean

  def cumpleEstrictamenteConVarias(jugadasAFiltrar : List[Jugada], resultadoEsperado : List[Jugada]) : Boolean = {
    jugadasAFiltrar.filter(cumpleCon(_)).toSet == resultadoEsperado.toSet
  }
}

case class SucesoRuleta(val numero: Int, val color: Option[Color]) extends Suceso {
  def esPar: Boolean = (numero % 2 == 0)
  def noEsCero: Boolean = numero != 0
  def mismaDocena(docena: Int): Boolean = numero / 12 == docena + 1

  def cumpleCon(jugada: Jugada): Boolean = jugada match {
    case NumeroJugado(numero_) => numero == numero_
    case DocenaJugada(docena) => mismaDocena(docena)
    case ColorJugado(color_) => color.contains(color_)
    case ParidadJugada(Par) => esPar && noEsCero
    case ParidadJugada(Impar) => !esPar && noEsCero
    case _ => false
  }
}

case class SucesoMoneda(val ladoMoneda: LadoMoneda, override val peso: Double) extends Suceso {
  def cumpleCon(jugada: Jugada): Boolean = jugada match {
    case JugadaMoneda(ladoMoneda_) => ladoMoneda == ladoMoneda_
    case _ => false
  }
}