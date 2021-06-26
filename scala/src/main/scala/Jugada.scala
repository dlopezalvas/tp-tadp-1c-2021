import Color.Color
import LadoMoneda.LadoMoneda
import Paridad.Paridad

abstract class Jugada(val peso: Int = 1) {
  def factorGanancia: Int
}

abstract class JugadaRuleta extends Jugada {} // diferencia con trait?

case class ColorJugado(val color: Color) extends JugadaRuleta {
  override def factorGanancia = 2
}

case class ParidadJugada(val paridad: Paridad) extends JugadaRuleta {
  override def factorGanancia = 2
}

case class NumeroJugado(val numero: Int) extends JugadaRuleta {
  override def factorGanancia = 36
}

case class DocenaJugada(val docena: Int) extends JugadaRuleta {
  override def factorGanancia = 3
}

case class JugadaMoneda(val ladoMoneda: LadoMoneda) extends Jugada {
  override def factorGanancia = 2
}