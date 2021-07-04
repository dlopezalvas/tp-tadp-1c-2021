import Tipos.{Apuesta, Dinero, Probabilidad}

case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){ //jugada sucesiva
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] = ???/*{
    apuestas.foldLeft(DistribucionParaApuestas(/*inserte semilla que tom sabe cual es*/))((apuesta, distribucion) => distribucion.combinar(apuesta))
  }*/

}
