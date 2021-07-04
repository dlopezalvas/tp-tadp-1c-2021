import Tipos.{Apuesta, Dinero}

trait Jugador {
  type Sucesion = List[List[Apuesta]]

  val dinero : Dinero
  def simularApuestasSucesivas(sucesion : Sucesion) : DistribucionParaApuestas =
    sucesion.foldLeft(List((this.dinero, 1))) {
      (distribucionResultanteAnterior, apuesta) => {
        DistribucionParaApuestas(DistribucionParaApuestas.unificarRepetidos(
          distribucionResultanteAnterior.flatMap { // TODO: no resuelve
            case (dineroAnterior, probaAnterior) if (dineroAnterior >= apuesta.dinero) =>
              apuesta.simular().distribucion map { case (dineroGanado, probaDeGanarDinero) =>
                (dineroAnterior + dineroGanado, probaAnterior * probaDeGanarDinero)
              }
            case x => List(x)
          }
        ))
      }
    }
}
