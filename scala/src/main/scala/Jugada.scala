import Color.Color
import LadoMoneda.LadoMoneda
import Paridad.Paridad
import Tipos.{Dinero}

abstract class Jugada() {
  def factorGanancia: Int

  def dineroSegun(apuesta: List[(Jugada, Dinero)]): Dinero = {
    (apuesta.
      filter { case (jugada, _) => jugada == this }
      map    { case (_, dinero) => dinero * factorGanancia }
    ).sum
  }
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