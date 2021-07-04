import Tipos._

case class Jugador(val montoInicial: Dinero, val criterio: CriterioJugador){
  def elegirPlanDeJuego(planesDeJuego: List[PlanDeJuego]) : PlanDeJuego = criterio(montoInicial, planesDeJuego.zip(planesDeJuego.map(plan => plan.aplicar(montoInicial))))
}

object criterioRacional extends CriterioJugador {
  def apply(montoInicial: Dinero, distribuciones: DistribucionPlanDeJuego): PlanDeJuego =
    distribuciones.maxBy(_._2.map {case (dinero, probabilidad) => dinero * probabilidad}.sum)._1
}

object criterioArriesgado extends CriterioJugador{
  def apply(montoInicial: Dinero, distribuciones: DistribucionPlanDeJuego): PlanDeJuego =
    distribuciones.maxBy(_._2.maxBy(_._1))._1
}

object criterioCauto extends CriterioJugador{
  def apply(montoInicial: Dinero, distribuciones: DistribucionPlanDeJuego): PlanDeJuego =
    distribuciones.maxBy(_._2.filter(_._1 >= montoInicial).map(_._2).sum)._1
}

case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] ={

  }
/*  [(1/37, $40), (36/7, $0),  (36/7, $20)]*/
}

/*[($200-RojoY$20-Par, $50-1, $60-Cruz), ($400Negro, $20Cara)] -> Planes de juego*/


