import Tipos.{Apuesta, Dinero, Probabilidad}

case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){ //jugada sucesiva
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] = {

  }
//  [(1/37, $40), (36/7, $0),  (36/7, $20)]
}

/*[($200-RojoY$20-Par, $50-1, $60-Cruz), ($400Negro, $20Cara)] -> Planes de juego*/


/*
* $30
*
* [($10, Cara), ($20, Rojo)]
*
*
* */