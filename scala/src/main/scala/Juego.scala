import LadoMoneda._
import Sucesos._
import Tipos.Probabilidad

trait Juego {
  def sucesosPosibles(): List[Suceso]

  def distribucionProbabilidad(): List[(Suceso, Probabilidad)] = ???


  def probabilidad(resultadoEsperado: ResultadoEsperado): Probabilidad ={
    sucesosPosibles().count(suceso => suceso.seCumple(resultadoEsperado))/ sucesosPosibles().length
  }
}

object Ruleta extends Juego { def sucesosPosibles: List[SucesoRuleta] = List(Cero, Uno, Dos, Tres, Cuatro, Cinco,
  Seis, Siete, Ocho, Nueve, Diez, Once, Doce, Trece, Catorce, Quince, Dieciseis) }

object CaraOCruz extends Juego { def sucesosPosibles: List[SucesoMoneda] = List(SucesoMoneda(Cara), SucesoMoneda(Cruz))}