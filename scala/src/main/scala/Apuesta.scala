import Tipos.{Dinero, Probabilidad}

case class Apuesta(val dinero:Dinero, resultadoEsperado: ResultadoEsperado, val juego: Juego) extends (Suceso => Dinero){
  override def apply(suceso: Suceso): Dinero =
    if(suceso.seCumple(resultadoEsperado))  resultadoEsperado.factorGanacia * dinero
    else 0
}

case class ApuestaCompuesta(val apuestas: List[Apuesta] = List[Apuesta]()){
  def apostar (apuesta :Apuesta) = ApuestaCompuesta(apuestas.appended(apuesta))

  def posiblesGanancias : Map[Dinero, Probabilidad] = {
    var resultados_ : Map[Dinero, Probabilidad] = Map[Dinero, Probabilidad]()
    for(
    suceso <- sucesos;
      apuesta <- apuestas
    ){
      resultados_ = resultados_ + (apuesta(suceso) -> (probabilidadDe(suceso) + probabilidadDeDinero(apuesta(suceso), resultados_)))
    }
    resultados_
  }

  private def sucesos : List[Suceso] = apuestas.head.juego.sucesosPosibles()

  private def probabilidadDe(suceso: Suceso) : Probabilidad = apuestas.head.juego.probabilidadSuceso(suceso)

  def probabilidadDeDinero(monto : Dinero, _resultados : Map[Dinero, Probabilidad]) : Probabilidad = {
    if (_resultados.contains(monto))
      _resultados(monto)
    else
      0
  }
}