import Tipos.{Dinero, Probabilidad}

case class PlanDeJuego(nombre: String, apuestas: List[Apuesta]){ //jugada sucesiva
  def aplicar(montoInicial: Dinero): List[(Dinero, Probabilidad)] =
    (apuestas.foldLeft(DistribucionParaApuestas(List((montoInicial, 1))))
      { (distribucion, apuesta) => distribucion.combinar(apuesta) }).distribucion
}
