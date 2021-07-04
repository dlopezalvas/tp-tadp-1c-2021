import Tipos._

case class Jugador(val montoInicial: Dinero, val criterio: CriterioJugador){
  def elegirPlanDeJuego(planesDeJuego: List[PlanDeJuego]) : PlanDeJuego = criterio(planesDeJuego.zip(planesDeJuego.map(plan => plan.aplicar(montoInicial))))
}

object criterioRacional extends CriterioJugador {
  def apply(distribuciones: DistribucionPlanDeJuego): PlanDeJuego = distribuciones.maxBy {
    case (plan, distribucion) => distribucion.map {case (dinero, probabilidad) => dinero * probabilidad}.sum
  }._1
}


case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] ={

  }
/*  [(1/37, $40), (36/7, $0)]*/
}

/*[($200-RojoY$20-Par, $50-1, $60-Cruz), ($400Negro, $20Cara)] -> Planes de juego*/


