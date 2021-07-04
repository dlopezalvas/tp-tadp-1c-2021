import Tipos.{Apuesta, Dinero, Probabilidad}

case class Jugador(val montoInicial: Dinero, val criterio: Criterio){
  def elegirPlanDeJuego(planesDeJuego: List[PlanDeJuego]) : PlanDeJuego{
    criterio(planesDeJuego.zip(planesDeJuego.map(plan -> plan.aplicar(montoIniical))).toMap)
  }
}

object criterioRacional extends List[(PlanDeJuego, List[(Dinero, Probabilidad)]) => PlanDeJuego {
  def apply(distribuciones: List[(PlanDeJuego, List[(Dinero, Probabilidad)]) : PlanDeJuego {
    distribuciones.maxBy{ _._1.sumBy((dinero, probabilidad) -> dinero * probabilidad)}
  }
}

/*  distribuciones.maxBy{(plan, distribucion) -> distribucion.sumBy((dinero, probabilidad) -> dinero * probabilidad)}*/

case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){

  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] ={

  }
/*  [(1/37, $40), (36/7, $0)]*/
}




/*[($200-RojoY$20-Par, $50-1, $60-Cruz), ($400Negro, $20Cara)] -> Planes de juego*/


