import Tipos.{Apuesta, Dinero, Probabilidad}

case class PlanDeJuego(val nombre: String, val apuestas: List[Apuesta]){ //jugada sucesiva
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] = ???/* {
    apuestas.foldRight(DistribucionParaApuestas(List.empty))((apuesta, distribucion) => distribucion.combinar(apuesta))
  }*/

}
