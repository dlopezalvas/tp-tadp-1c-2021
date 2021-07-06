import Tipos.{Dinero, Peso}


trait Apuesta {
  def dinero() : Dinero = apuesta.map(_._2).sum // TODO: test si rompe con lista vacía
  def simular() : DistribucionParaApuestas
  def apuesta() : List[(Jugada, Dinero)]
}


case class ApuestaRuleta(apuesta: List[(JugadaRuleta, Dinero)]) extends Apuesta {
  def simular() : DistribucionParaApuestas = Ruleta.simularApuesta(this)
}


case class ApuestaMoneda(apuesta: List[(JugadaMoneda, Dinero)], pesoCara: Peso = 1, pesoCruz: Peso = 1) extends Apuesta {
  def simular() : DistribucionParaApuestas = Moneda(pesoCara, pesoCruz).simularApuesta(this)
}
