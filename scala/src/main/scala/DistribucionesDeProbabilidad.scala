import Tipos.{Apuesta, Dinero, Probabilidad}


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
  def combinar(apuesta: Apuesta): DistribucionParaApuestas ={
    var nuevaDistribucion :List[(Dinero,Probabilidad)] = List.empty
    distribucion.foreach{
      case (dineroOriginal, probabilidad) if(dineroOriginal >= apuesta.montoTotalApostado) =>
        apuesta.simular().forEach{ case (dineroGanado, probabilidadDineroGanado)
          nuevaDistribucion.add((dineroOriginal - apuesta.montoTotalApostado + dineroGanado), (probabilidad * probabilidadDineroGanado))
        }
      case _ => this
    }
    //Cosa magica que elimina repetidos y junta las probabilidades o ver en el add si ya existe.
  }
}
case object DistribucionParaApuestas {
  def unificarRepetidos(distribucion: List[(Dinero, Probabilidad)]): List[(Dinero, Probabilidad)] = {
    val dineroSinRepetidos = distribucion.map(_._1).toSet
    dineroSinRepetidos.map(dinero => (dinero, distribucion.filter(_._1 == dinero).map(_._2).sum)).toList
  }

  def desdeDistribucionParaJugadas(distribucionParaJugadas: DistribucionParaJugadas, apuestas: List[Apuesta]) : DistribucionParaApuestas = {
    DistribucionParaApuestas(unificarRepetidos(distribucionParaJugadas.distribucion
        .map { case (jugadas, probabilidad) => (jugadas.map(_.dineroSegun(apuestas)).sum , probabilidad)}))
  }
}
