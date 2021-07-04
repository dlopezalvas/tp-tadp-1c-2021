object Tipos {
  type Apuesta = (Jugada, Dinero)
  type Dinero = Double
  type Probabilidad = Double
  type Peso = Double
  type DistribucionPlanDeJuego = List[(PlanDeJuego, List[(Dinero, Probabilidad)])]
  type CriterioJugador = DistribucionPlanDeJuego => PlanDeJuego
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
