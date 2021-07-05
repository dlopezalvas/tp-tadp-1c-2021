import Tipos.{Dinero, Probabilidad}


// DistribucionParaJugadas: un wrapper para la distribución cruda
case class DistribucionParaJugadas(distribucion: List[(List[Jugada], Probabilidad)]) {
  
  def incrementarProbabilidadDe(combinacionDeJugadas: List[Jugada], probabilidadASumar: Probabilidad): DistribucionParaJugadas = {
    if(existe(combinacionDeJugadas)){
      DistribucionParaJugadas(distribucion.map {
          case (jugadas, probabilidad) if (jugadas.toSet == combinacionDeJugadas.toSet) => (jugadas, probabilidad + probabilidadASumar)
          case x => x
        })
    }
    DistribucionParaJugadas(distribucion.appended((combinacionDeJugadas, probabilidadASumar)))
  }

  def existe(combinacionDeJugadas: List[Jugada]) =
    distribucion.exists{case (jugadas, _) => (jugadas.toSet == combinacionDeJugadas.toSet)}
}


// DistribucionParaApuestas: un wrapper para la distribución cruda
case class DistribucionParaApuestas(distribucion: List[(Dinero, Probabilidad)]) {
  def combinar(apuesta: Apuesta): DistribucionParaApuestas = {
      // DRA es this, apuesta es apuesta xd
      DistribucionParaApuestas(DistribucionParaApuestas.unificarRepetidos(
        distribucion flatMap {
          case (dineroAnterior, probaAnterior) if dineroAnterior >= apuesta.dinero =>
            apuesta.simular().distribucion map { case (dineroGanado, probaDeGanarDinero) =>
              (dineroAnterior + dineroGanado - apuesta.dinero, probaAnterior * probaDeGanarDinero)
            }
          case x => List(x)
        }
      ))
  }
}
case object DistribucionParaApuestas {
  def unificarRepetidos(distribucion: List[(Dinero, Probabilidad)]): List[(Dinero, Probabilidad)] = {
    val dineroSinRepetidos = distribucion.map(_._1).toSet
    dineroSinRepetidos.map(dinero => (dinero, distribucion.filter(_._1 == dinero).map(_._2).sum)).toList
  }

  def desdeDistribucionParaJugadas(distribucionParaJugadas: DistribucionParaJugadas, apuestas: List[(Jugada, Dinero)]) : DistribucionParaApuestas = {
    DistribucionParaApuestas(unificarRepetidos(distribucionParaJugadas.distribucion
        .map { case (jugadas, probabilidad) => (jugadas.map(_.dineroSegun(apuestas)).sum , probabilidad)}))
  }
}
