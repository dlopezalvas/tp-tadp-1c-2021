import Sucesos._
import Tipos.{Dinero, Probabilidad}

trait Juego {
  def sucesosPosibles(): List[Suceso]

  def distribucionProbabilidad(): List[(Suceso, Probabilidad)] = ??? //TODO preguntar que onda

  def metodoFeo(suceso: Suceso, resultadoEsperado: ResultadoEsperado): Int = //TODO arreglar estos nombres horribles
    if(suceso.seCumple(resultadoEsperado)) resultadoEsperado.peso else 0

  def probabilidad(resultadoEsperado: ResultadoEsperado): Probabilidad ={ //TODO arreglar tema pesos de todos los resultados
    sucesosPosibles().map(suceso => metodoFeo(suceso, resultadoEsperado)).sum / sucesosPosibles().length
  }

  def probabilidadSuceso(suceso: Suceso): Probabilidad ={ //TODO ver peso
    1.0/sucesosPosibles().length
  }

  def jugarA(resultadoEsperado: ResultadoEsperado, monto : Dinero) : Apuesta = {
    if (!esValido(resultadoEsperado)) throw new RuntimeException //TODO hacer error jugada Invalida
    Apuesta(monto, resultadoEsperado, this)
  }

  protected def esValido(resultadoEsperado: ResultadoEsperado) : Boolean
}

object Ruleta extends Juego { def sucesosPosibles: List[SucesoRuleta] = sucesosRuleta

  override protected def esValido(resultadoEsperado: ResultadoEsperado): Boolean = resultadoEsperado match {
    // case Numero(n) if (0 <= n) && (n <= 36) // TODO esto no creo que funcione como espero
    case Numero(_)
         | ColorEsperado(_)
         | ParidadEsperada(_)
         | Docena(_) => true
    case _ => false
  }
}

object CaraOCruz extends Juego { def sucesosPosibles: List[SucesoMoneda] = sucesosCaraCruz

  override protected def esValido(resultadoEsperado: ResultadoEsperado): Boolean = resultadoEsperado match {
    case LadoEsperado(_) => true
    case _ => false
  }
}