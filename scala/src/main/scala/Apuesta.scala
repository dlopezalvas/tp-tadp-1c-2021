import Tipos.Dinero

case class Apuesta(val dinero:Dinero, resultadoEsperado: ResultadoEsperado) extends (Suceso => Dinero){
  override def apply(suceso: Suceso): Dinero = if(suceso.seCumple(resultadoEsperado))  resultadoEsperado.factorGanacia * dinero
  else 0
}