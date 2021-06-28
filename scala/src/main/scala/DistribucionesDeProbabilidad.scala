import Tipos.{Dinero, Probabilidad}

case class DistribucionJugada(val distribucion: List[(List[Jugada], Probabilidad)]) {
  def sumarProbabilidad(combinacionDeJugadas: List[Jugada], probabilidadASumar: Probabilidad): DistribucionJugada = {
    var noEstabaContemplada = true
    var retorno = DistribucionJugada(distribucion.map(t => t match {
      case (c: List[Jugada], p: Probabilidad) if (c.toSet == combinacionDeJugadas.toSet) => {
        noEstabaContemplada = false
        (c, p + probabilidadASumar)
      }
      case x => x
    }))
    if (noEstabaContemplada) DistribucionJugada(distribucion.appended((combinacionDeJugadas, probabilidadASumar)))
    else retorno
  }
}

case class DistribucionApuesta(val distribucion: List[(Dinero, Probabilidad)]) {}
case object DistribucionApuesta {
  def sumarRepetidos(distribucion: List[(Dinero, Probabilidad)]): DistribucionApuesta = {
    var dineroSinRepetidos = distribucion.map(_ match { case (dinero, _) => dinero }).toSet
    DistribucionApuesta(dineroSinRepetidos.map(dinero => (dinero, (distribucion filter {
      case (dinero_, probabilidad_) => dinero == dinero_
    } map { case (dinero_, probabilidad_) => probabilidad_}).sum)).toList)
  }
}
