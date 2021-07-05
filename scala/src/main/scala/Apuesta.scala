import Tipos.Dinero

case class Apuesta[T <: Juego](apuesta: List[(Jugada, Dinero)], juego: T) {
  def dinero() : Dinero = apuesta.map(_._2).sum

  def simular[T]() : DistribucionParaApuestas = juego match {
    case Ruleta => Ruleta.simularApuestas(apuesta)
    case
  }
}


case class Apuesta[T <: Juego](apuesta: List[(Jugada, Dinero)], juego: T) {
  def dinero() : Dinero = apuesta.map(_._2).sum // TODO: test si rompe con lista vacía

  def simular() : DistribucionParaApuestas = juego.simularApuestas(apuesta)
}

