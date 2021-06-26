import Tipos.{Dinero, Probabilidad}

case class DDPJugadas(val distribucion: List[(List[Jugada], Probabilidad)]) {
  def sumarProbabilidad(combinacionDeJugadas: List[Jugada], probabilidadASumar: Probabilidad): DDPJugadas = {
    var noEstabaContemplada = true
    var retorno = DDPJugadas(distribucion.map(t => t match {
      case (c: List[Jugada], p: Probabilidad) if (c.toSet == combinacionDeJugadas.toSet) => {
        noEstabaContemplada = false
        (c, p + probabilidadASumar)
      }
      case x => x
    }))
    if (noEstabaContemplada) DDPJugadas(distribucion.appended((combinacionDeJugadas, probabilidadASumar)))
    else retorno
  }
}

case class DDPApuesta(val distribucion: List[(Dinero, Probabilidad)]) {}
case object DDPApuesta {
  def sumarRepetidos(distribucion: List[(Dinero, Probabilidad)]): DDPApuesta = {
    var dineroSinRepetidos = distribucion.map(_ match { case (dinero, _) => dinero }).toSet
    DDPApuesta(dineroSinRepetidos.map(dinero => (dinero, (distribucion filter {
      case (dinero_, probabilidad_) => dinero == dinero_
    } map { case (dinero_, probabilidad_) => probabilidad_}).sum)).toList)
  }
}
