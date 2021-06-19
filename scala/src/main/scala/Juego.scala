import Sucesos._
import Tipos.Probabilidad

trait Juego {
  def sucesosPosibles(): List[Suceso]

  def distribucionProbabilidad(): List[(Suceso, Probabilidad)] = ???

  def funcionFea(suceso: Suceso, resultadoEsperado: ResultadoEsperado): Int = //TODO arreglar estos nombres horribles
    if(suceso.seCumple(resultadoEsperado)) resultadoEsperado.peso else 0

  def probabilidad(resultadoEsperado: ResultadoEsperado): Probabilidad ={
    sucesosPosibles().map(suceso => funcionFea(suceso, resultadoEsperado)).sum / sucesosPosibles().length
  }
}

object Ruleta extends Juego { def sucesosPosibles: List[SucesoRuleta] = sucesosRuleta }

object CaraOCruz extends Juego { def sucesosPosibles: List[SucesoMoneda] = sucesosCaraCruz}