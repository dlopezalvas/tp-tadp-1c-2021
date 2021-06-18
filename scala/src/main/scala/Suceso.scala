import Color.{Color, Negro}
import LadoMoneda.LadoMoneda
import Paridad._
import Tipos.Dinero

trait Suceso{
  def seCumple(resultadoEsperado: ResultadoEsperado): Boolean
}

case class SucesoMoneda(val ladoMoneda: LadoMoneda) extends Suceso {
  override def seCumple(resultadoEsperado: ResultadoEsperado): Boolean = resultadoEsperado match {
    case LadoEsperado(lado) => ladoMoneda.equals(lado)
  }
}

case class SucesoRuleta(val valor: Int, color: Option[Color]) extends Suceso {

  def esPar: Boolean = valor%2 == 0

  def mismaDocena(docena: Int): Boolean = valor/12 == docena + 1

  def seCumple(resultadoEsperado: ResultadoEsperado): Boolean =
    resultadoEsperado match{
      case Numero(numero) => valor == numero
      case Docena(docena) => mismaDocena(docena)
      case ColorEsperado(colorEsperado) => color.equals(colorEsperado)
      case ParidadEsperada(Par) => esPar
      case ParidadEsperada(Impar) => !esPar
      case _ => false
  }

}

object Sucesos{
    val Cero = SucesoRuleta(0, None)
    val Uno = SucesoRuleta(1, Some(Color.Rojo))
    val Dos = SucesoRuleta(2, Some(Color.Negro))
    val Tres = SucesoRuleta(3, Some(Color.Rojo))
    val Cuatro = SucesoRuleta(4, Some(Color.Negro))
    val Cinco = SucesoRuleta(5, Some(Color.Rojo))
    val Seis = SucesoRuleta(6, Some(Color.Negro))
    val Siete = SucesoRuleta(7,Some(Color.Rojo))
    val Ocho = SucesoRuleta(8, Some(Color.Negro))
    val Nueve = SucesoRuleta(9, Some(Color.Rojo))
    val Diez = SucesoRuleta(10, Some(Color.Negro))
    val Once = SucesoRuleta(11, Some(Color.Negro))
    val Doce = SucesoRuleta(12, Some(Color.Rojo))
    val Trece = SucesoRuleta(13, Some(Color.Negro))
    val Catorce = SucesoRuleta(14, Some(Color.Rojo))
    val Quince = SucesoRuleta(15, Some(Color.Negro))
    val Dieciseis = SucesoRuleta(16, Some(Color.Rojo))
    //...
}

