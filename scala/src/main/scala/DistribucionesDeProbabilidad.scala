import Tipos.{Apuesta, Dinero, Probabilidad}


// DistribucionParaJugadas: un wrapper para la distribución cruda
case class DistribucionParaJugadas(distribucion: List[(List[Jugada], Probabilidad)]) {

  // TODO: refactor para deshacerse de ese flag feo
  def incrementarProbabilidadDe(combinacionDeJugadas: List[Jugada], probabilidadASumar: Probabilidad): DistribucionParaJugadas = {
    var laCombinacionDeJugadasNoEstabaContemplada = true
    val distribucionConUnaProbabilidadIncrementada = DistribucionParaJugadas(distribucion.map {
      case (jugadas, probabilidad) if (jugadas.toSet == combinacionDeJugadas.toSet) => {
        laCombinacionDeJugadasNoEstabaContemplada  = false
        (jugadas, probabilidad + probabilidadASumar)
      }
      case x => x
    })
    if (laCombinacionDeJugadasNoEstabaContemplada)
      DistribucionParaJugadas(distribucion.appended((combinacionDeJugadas, probabilidadASumar)))
    else distribucionConUnaProbabilidadIncrementada
  }
}


// DistribucionParaApuestas: un wrapper para la distribución cruda
case class DistribucionParaApuestas(distribucion: List[(Dinero, Probabilidad)]) {}
case object DistribucionParaApuestas {
  def unificarRepetidos(distribucion: List[(Dinero, Probabilidad)]): List[(Dinero, Probabilidad)] = {
    // primero necesita obtener los montos como claves únicas (descartando los repetidos con toSet)
    val dineroSinRepetidos = distribucion.map(_ match { case (dinero, _) => dinero }).toSet
    // después mapea cada monto a su correspondiente par (dinero, probabilidadTotalDeEseDinero)
    dineroSinRepetidos.map( dinero =>
      (
        dinero,
        ( // probabilidadTotalDeEseDinero:
          distribucion filter { case (dinero_, _) => dinero == dinero_ }
                       map    { case (_, probabilidad_) => probabilidad_ }
        ).sum
      )
    ).toList // convierte el Set a List para devolver el tipo correcto
  }

  def desdeDistribucionParaJugadas(distribucionParaJugadas: DistribucionParaJugadas, apuestas: List[Apuesta]) : DistribucionParaApuestas = {
    DistribucionParaApuestas(unificarRepetidos(
      distribucionParaJugadas
        .distribucion
        .map { // mapea cada conjunto de jugadas a su correspondiente dinero según las apuestas dadas
          case (jugadas, probabilidad) => (
            jugadas.map(_.dineroSegun(apuestas)).sum,
            probabilidad
          )
        }
    ))
  }
}
