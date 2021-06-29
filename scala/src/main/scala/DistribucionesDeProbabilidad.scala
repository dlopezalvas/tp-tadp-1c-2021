import Tipos.{Apuesta, Dinero, Probabilidad}


// DistribucionParaJugadas: un wrapper para la distribución cruda
case class DistribucionParaJugadas(distribucion: List[(List[Jugada], Probabilidad)]) {

  // este método es medio feo y habría que rehacerlo; se entiende en las últimas 4 líneas
  // TODO: refactor para deshacerse de ese flag feo
  def incrementarProbabilidadDe(combinacionDeJugadas: List[Jugada], probabilidadASumar: Probabilidad): DistribucionParaJugadas = {
    var laCombinacionDeJugadasEstabaContempladaEnLaLista = false
    val distribucionConUnaProbabilidadIncrementada = DistribucionParaJugadas(
      distribucion.map {
        case (jugadas, probabilidad) if (jugadas.toSet == combinacionDeJugadas.toSet) => {
          laCombinacionDeJugadasEstabaContempladaEnLaLista  = true
          (jugadas, probabilidad + probabilidadASumar)
        }
        case x => x
      }
    )
    if (laCombinacionDeJugadasEstabaContempladaEnLaLista) // si existe ya la comb. de jugadas, solo se suma la prob.
      distribucionConUnaProbabilidadIncrementada
    else // si no, se agrega una nueva tupla para esa comb. de jugadas
      DistribucionParaJugadas(distribucion.appended((combinacionDeJugadas, probabilidadASumar)))
  }
}


// DistribucionParaApuestas: un wrapper para la distribución cruda
case class DistribucionParaApuestas(distribucion: List[(Dinero, Probabilidad)]) {}
case object DistribucionParaApuestas {
  def unificarRepetidos(distribucion: List[(Dinero, Probabilidad)]): List[(Dinero, Probabilidad)] = {
    // primero necesita obtener los montos (dinero) como claves únicas (descartando los repetidos con toSet)
    val dineroSinRepetidos = distribucion.map(_ match { case (dinero, _) => dinero }).toSet
    // después mapea cada monto/dinero a su correspondiente par (dinero, probabilidadTotalDeEseDinero)
    dineroSinRepetidos.map( dinero =>
      (
        dinero,
        ( // probabilidadTotalDeEseDinero:
          distribucion filter { case (dinero_, _) => dinero == dinero_ }
                       map    { case (_, probabilidad_) => probabilidad_ }
        ).sum // es la suma de las probabilidades de ese monto/dinero
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
