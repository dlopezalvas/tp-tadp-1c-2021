import Tipos._

case class Jugador(val montoInicial: Dinero, val criterio: CriterioJugador){
  def elegirPlanDeJuego(planesDeJuego: List[PlanDeJuego]) : PlanDeJuego =
    criterio(montoInicial, planesDeJuego.zip(planesDeJuego.map(plan => plan.aplicar(montoInicial))))
}