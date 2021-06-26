import Color.Color
import LadoMoneda.{LadoMoneda}
import Paridad.{Impar, Par}

trait Suceso {
  def peso() : Double = 1;
  def cumpleCon(jugada : Jugada) : Boolean

  def cumpleConVarias(jugadasAFiltrar : List[Jugada], resultadoEsperado : List[Jugada]) : Boolean = {
    jugadasAFiltrar.filter(cumpleCon(_)).toSet == resultadoEsperado.toSet
  }
}

case class SucesoRuleta(val numero: Int, val color: Option[Color]) extends Suceso {
  def esPar: Boolean = (numero % 2 == 0) && (numero != 0)
  def mismaDocena(docena: Int): Boolean = numero / 12 == docena + 1

  def cumpleCon(jugada: Jugada): Boolean = jugada match {
    case NumeroJugado(numero_) => numero_ == numero
    case DocenaJugada(docena) => mismaDocena(docena)
    case ColorJugado(colorEsperado) => color.contains(colorEsperado)
    case ParidadJugada(Par) => esPar
    case ParidadJugada(Impar) => !esPar
    case _ => false
  }
}

case class SucesoMoneda(val ladoMoneda: LadoMoneda) extends Suceso {
  def cumpleCon(jugada: Jugada): Boolean = jugada match {
    case JugadaMoneda(ladoMoneda_) => ladoMoneda == ladoMoneda_
    case _ => false
  }
}