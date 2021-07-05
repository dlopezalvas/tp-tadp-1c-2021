object Tipos {
  type Dinero = Double
  type Probabilidad = Double
  type Peso = Double
  type DistribucionPlanDeJuego = (PlanDeJuego, List[(Dinero, Probabilidad)])
  type CriterioJugador = (Dinero, List[DistribucionPlanDeJuego]) => PlanDeJuego
}

object Color extends Enumeration { // TODO va en otro archivo
  type Color = Value
  val Rojo, Negro = Value
}

object Paridad extends Enumeration{
  type Paridad = Value
  val Par, Impar = Value
}

object LadoMoneda extends Enumeration{
  type LadoMoneda = Value
  val Cara, Cruz = Value
}

object CosasTesting {
  val algo1 = PlanDeJuego("algo1", List(Apuesta(List((ColorJugado(Color.Rojo), 10)), Ruleta), Apuesta(List((ParidadJugada(Paridad.Par), 10)), Ruleta)))
  val algo2 = PlanDeJuego("algo2", List(Apuesta(List((ColorJugado(Color.Rojo), 10), (ParidadJugada(Paridad.Par), 10)), Ruleta), Apuesta(List((JugadaMoneda(LadoMoneda.Cara), 30)), Moneda())))
}