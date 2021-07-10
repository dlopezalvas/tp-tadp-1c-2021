import Tipos.{CriterioJugador, Dinero, DistribucionPlanDeJuego}

object criterioRacional extends CriterioJugador {
  def apply(montoInicial: Dinero, distribuciones: List[DistribucionPlanDeJuego]): PlanDeJuego =
    distribuciones.maxBy(_._2.map {case (dinero, probabilidad) => dinero * probabilidad}.sum)._1
}

object criterioArriesgado extends CriterioJugador{
  def apply(montoInicial: Dinero, distribuciones: List[DistribucionPlanDeJuego]): PlanDeJuego =
    distribuciones.maxBy(_._2.maxBy(_._1))._1
}

object criterioCauto extends CriterioJugador{
  def apply(montoInicial: Dinero, distribuciones: List[DistribucionPlanDeJuego]): PlanDeJuego =
    distribuciones.maxBy(_._2.filter(_._1 >= montoInicial).map(_._2).sum)._1
}

