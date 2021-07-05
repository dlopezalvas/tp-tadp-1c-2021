import Tipos.Dinero


case class Apuesta(apuesta: List[(Jugada, Dinero)], juego: Juego) {
  def dinero() : Dinero = apuesta.map(_._2).sum // TODO: test si rompe con lista vacía

  def simular() : DistribucionParaApuestas = juego match {
    case Ruleta => Ruleta.simularApuesta(this)
    case moneda @ Moneda(_, _) => moneda.simularApuesta(this)
  }
}

